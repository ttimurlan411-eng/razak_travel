const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const logger = require('firebase-functions/logger');
const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const Stripe = require('stripe');

admin.initializeApp();

const db = admin.firestore();
const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

const functionsRegion = 'us-central1';
const bookingCollection = db.collection('bookings');
const notificationCollection = db.collection('notifications');
const tourCollection = db.collection('tours');
const userCollection = db.collection('users');

exports.createCheckoutSession = onRequest(
  {
    region: functionsRegion,
  },
  (request, response) => {
    cors(request, response, async () => {
      if (request.method === 'OPTIONS') {
        response.status(204).send('');
        return;
      }

      if (request.method !== 'POST') {
        response.status(405).json({ error: 'error_generic' });
        return;
      }

      try {
        const body = normalizeCheckoutRequest(request.body);
        const existingBooking = await findBookingByRequestId(body.checkoutRequestId);

        if (existingBooking) {
          if (existingBooking.paid !== true) {
            try {
              await completeTestCheckout({
                bookingId: existingBooking.id,
              });
            } catch (error) {
              await releaseReservation({
                bookingId: existingBooking.id,
                nextStatus: 'payment_failed',
                nextCheckoutStatus: 'failed',
              });
              throw error;
            }
          }

          const latestBookingSnapshot = await bookingCollection.doc(existingBooking.id).get();
          const latestBooking = latestBookingSnapshot.data() || existingBooking;

          response.status(200).json({
            bookingId: existingBooking.id,
            checkoutUrl: latestBooking.checkoutUrl || '',
            checkoutStatus:
              latestBooking.paid === true
                ? 'completed'
                : latestBooking.checkoutStatus || 'initiated',
          });
          return;
        }

        const bookingRef = bookingCollection.doc();
        await reserveSeatsAndCreatePendingBooking(bookingRef, body);

        try {
          await completeTestCheckout({
            bookingId: bookingRef.id,
          });
        } catch (error) {
          await releaseReservation({
            bookingId: bookingRef.id,
            nextStatus: 'payment_failed',
            nextCheckoutStatus: 'failed',
          });
          throw error;
        }

        const bookingSnapshot = await bookingRef.get();
        const booking = bookingSnapshot.data() || {};

        response.status(200).json({
          bookingId: String(booking.id || bookingRef.id),
          checkoutUrl: String(booking.checkoutUrl || ''),
          checkoutStatus: String(booking.checkoutStatus || 'completed'),
        });
      } catch (error) {
        logger.error('createCheckoutSession failed', error);
        response.status(400).json({
          error: mapCheckoutError(error),
        });
      }
    });
  },
);

exports.stripeWebhook = onRequest(
  {
    region: functionsRegion,
    secrets: [stripeSecretKey, stripeWebhookSecret],
  },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).send('Method not allowed');
      return;
    }

    const stripe = new Stripe(stripeSecretKey.value());
    const signature = request.headers['stripe-signature'];

    if (!signature) {
      response.status(400).send('Missing Stripe signature');
      return;
    }

    let event;

    try {
      event = stripe.webhooks.constructEvent(
        request.rawBody,
        signature,
        stripeWebhookSecret.value(),
      );
    } catch (error) {
      logger.error('Webhook signature verification failed', error);
      response.status(400).send('Invalid signature');
      return;
    }

    try {
      switch (event.type) {
        case 'checkout.session.completed':
          await markBookingPaid(event.data.object);
          break;
        case 'checkout.session.expired':
          await releaseReservation({
            bookingId: extractBookingId(event.data.object),
            nextStatus: 'payment_expired',
            nextCheckoutStatus: 'expired',
            stripeCheckoutSessionId: event.data.object.id,
          });
          break;
        default:
          logger.info(`Unhandled Stripe event: ${event.type}`);
      }

      response.status(200).json({ received: true });
    } catch (error) {
      logger.error('Webhook handling failed', error);
      response.status(500).send('Webhook processing failed');
    }
  },
);

exports.sendNotificationPush = onDocumentCreated(
  {
    region: functionsRegion,
    document: 'notifications/{notificationId}',
  },
  async (event) => {
    const snapshot = event.data;
    const notification = snapshot?.data();

    if (!notification) {
      return;
    }

    try {
      const title = String(notification.title || '').trim();
      const message = String(notification.message || '').trim();
      const type = String(notification.type || '').trim();
      const tourId = String(notification.tourId || '').trim();
      const targetUserId = String(notification.targetUserId || '').trim();

      const tokens = targetUserId
        ? await loadTokensForUser(targetUserId)
        : await loadAllTokens();

      if (tokens.length === 0) {
        logger.info('No FCM tokens found for notification', snapshot.id);
        return;
      }

      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: title || 'Razak Travel',
          body: message || title || 'New update',
        },
        data: {
          notificationId: snapshot.id,
          type,
          tourId,
        },
      });
    } catch (error) {
      logger.error('sendNotificationPush failed', error);
    }
  },
);

function normalizeCheckoutRequest(body) {
  const requestBody = typeof body === 'object' && body !== null ? body : {};
  const tourId = String(requestBody.tourId || '').trim();
  const clientName = String(requestBody.clientName || '').trim();
  const phone = String(requestBody.phone || '').trim();
  const selectedDate = String(requestBody.selectedDate || '').trim();
  const currency = String(requestBody.currency || 'usd').trim().toLowerCase();
  const checkoutRequestId = String(requestBody.checkoutRequestId || '').trim();
  const seats = Number.parseInt(requestBody.seats, 10);

  if (
    !tourId ||
    !clientName ||
    !phone ||
    !selectedDate ||
    !isValidDateOnly(selectedDate) ||
    !checkoutRequestId ||
    !Number.isFinite(seats) ||
    seats <= 0
  ) {
    throw new Error('fill_all_fields');
  }

  return {
    tourId,
    clientName,
    phone,
    selectedDate,
    seats,
    currency: currency || 'usd',
    checkoutRequestId,
  };
}

async function findBookingByRequestId(checkoutRequestId) {
  const snapshot = await bookingCollection
    .where('checkoutRequestId', '==', checkoutRequestId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const doc = snapshot.docs[0];
  return {
    id: doc.id,
    ...doc.data(),
  };
}

async function reserveSeatsAndCreatePendingBooking(bookingRef, payload) {
  const bookingNotificationRef = notificationCollection.doc();
  const tourRef = tourCollection.doc(payload.tourId);
  let reservation;

  await db.runTransaction(async (transaction) => {
    const tourSnapshot = await transaction.get(tourRef);
    const tour = tourSnapshot.data();

    if (!tour) {
      throw new Error('error_generic');
    }

    const totalSeats = toInt(tour.totalSeats);
    const bookedSeats = toInt(tour.bookedSeats);
    const reservedSeats = toInt(tour.reservedSeats);
    const availableSeats = Math.max(totalSeats - bookedSeats - reservedSeats, 0);

    if (payload.seats > availableSeats) {
      throw new Error('not_enough_seats_available');
    }

    const unitAmount = Math.round(Number(tour.price || 0) * 100);
    if (!Number.isFinite(unitAmount) || unitAmount <= 0) {
      throw new Error('payment_failed');
    }

    reservation = {
      totalAmount: (unitAmount * payload.seats) / 100,
      tourName: String(tour.name || 'Tour booking'),
      unitAmount,
    };

    transaction.set(bookingRef, {
      id: bookingRef.id,
      amount: reservation.totalAmount,
      checkoutRequestId: payload.checkoutRequestId,
      checkoutStatus: 'initiated',
      clientName: payload.clientName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      currency: payload.currency,
      paid: false,
      paymentCompletedAt: null,
      phone: payload.phone,
      selectedDate: payload.selectedDate,
      seats: payload.seats,
      status: 'payment_pending',
      stripeCheckoutSessionId: '',
      stripePaymentIntentId: '',
      checkoutUrl: '',
      tourId: payload.tourId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(
      bookingNotificationRef,
      buildNotificationData({
        title: 'Booking created',
        message: `${payload.clientName} created a booking for ${reservation.tourName}.`,
        tourId: payload.tourId,
      }),
    );

    transaction.set(
      tourRef,
      {
        reservedSeats: reservedSeats + payload.seats,
      },
      { merge: true },
    );
  });

  return reservation;
}

async function markBookingPaid(session) {
  const bookingId = extractBookingId(session);
  if (!bookingId) {
    logger.warn('checkout.session.completed missing bookingId', session.id);
    return;
  }

  const bookingRef = bookingCollection.doc(bookingId);
  const paymentNotificationRef = notificationCollection.doc();

  await db.runTransaction(async (transaction) => {
    const bookingSnapshot = await transaction.get(bookingRef);
    const booking = bookingSnapshot.data();

    if (!booking) {
      logger.warn('Booking not found for checkout.session.completed', bookingId);
      return;
    }

    if (booking.paid === true) {
      return;
    }

    const tourRef = tourCollection.doc(String(booking.tourId));
    const tourSnapshot = await transaction.get(tourRef);
    const tour = tourSnapshot.data();

    if (!tour) {
      throw new Error('Tour not found for paid booking');
    }

    const seats = toInt(booking.seats);
    const bookedSeats = toInt(tour.bookedSeats);
    const reservedSeats = toInt(tour.reservedSeats);

    transaction.set(
      tourRef,
      {
        bookedSeats: bookedSeats + seats,
        reservedSeats: Math.max(reservedSeats - seats, 0),
      },
      { merge: true },
    );

    transaction.set(
      bookingRef,
      {
        paid: true,
        status: 'paid',
        checkoutStatus: 'completed',
        stripeCheckoutSessionId: session.id || '',
        stripePaymentIntentId: String(session.payment_intent || ''),
        paymentCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    transaction.set(
      paymentNotificationRef,
      buildNotificationData({
        title: 'Payment successful',
        message: `Payment confirmed for ${String(booking.clientName || 'customer')} on ${String(tour.name || 'tour')}.`,
        tourId: String(booking.tourId || ''),
      }),
    );
  });
}

async function completeTestCheckout({ bookingId }) {
  await markBookingPaid({
    id: `test_session_${bookingId}`,
    payment_intent: `test_payment_intent_${bookingId}`,
    metadata: {
      bookingId,
    },
  });
}

async function releaseReservation({
  bookingId,
  nextStatus,
  nextCheckoutStatus,
  stripeCheckoutSessionId = '',
}) {
  if (!bookingId) {
    return;
  }

  const bookingRef = bookingCollection.doc(bookingId);

  await db.runTransaction(async (transaction) => {
    const bookingSnapshot = await transaction.get(bookingRef);
    const booking = bookingSnapshot.data();

    if (!booking || booking.paid === true) {
      return;
    }

    const tourRef = tourCollection.doc(String(booking.tourId));
    const tourSnapshot = await transaction.get(tourRef);
    const tour = tourSnapshot.data();

    if (tour) {
      const seats = toInt(booking.seats);
      const reservedSeats = toInt(tour.reservedSeats);

      transaction.set(
        tourRef,
        {
          reservedSeats: Math.max(reservedSeats - seats, 0),
        },
        { merge: true },
      );
    }

    transaction.set(
      bookingRef,
      {
        checkoutStatus: nextCheckoutStatus,
        status: nextStatus,
        stripeCheckoutSessionId:
          stripeCheckoutSessionId || String(booking.stripeCheckoutSessionId || ''),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

function extractBookingId(session) {
  return String(session?.metadata?.bookingId || '').trim();
}

function mapCheckoutError(error) {
  const code =
    error instanceof Error ? error.message : String(error || 'payment_failed');

  if (
    code === 'fill_all_fields' ||
    code === 'not_enough_seats_available'
  ) {
    return code;
  }

  return 'payment_failed';
}

function toInt(value) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

function buildNotificationData({ title, message, tourId }) {
  return {
    title: String(title || '').trim(),
    message: String(message || '').trim(),
    tourId: String(tourId || '').trim(),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function loadTokensForUser(userId) {
  const snapshot = await userCollection.doc(userId).get();
  const token = String(snapshot.data()?.fcmToken || '').trim();
  return token ? [token] : [];
}

async function loadAllTokens() {
  const snapshot = await userCollection.get();
  const tokens = snapshot.docs
    .map((doc) => String(doc.data().fcmToken || '').trim())
    .filter(Boolean);

  return [...new Set(tokens)];
}

function isValidDateOnly(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const parsed = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(parsed.getTime()) && parsed.toISOString().startsWith(value);
}
