# Digital Store, Orders & Billing

The MYADS Mobile App connects directly to the backend **Digital Products Store (`/store`)**, **Order Tracking (`/orders`)**, and **Paid Subscriptions (`/billing`)**.

---

## 1. Store Product Catalog (`StoreProductsScreen`)

Members can browse downloadable digital items (scripts, themes, plugins, graphics):
* Filter by category or search by keywords.
* Product detail screen with screenshots, descriptions, version numbers, and file sizes.
* Purchase items using Points (PTS) or payment gateways.

---

## 2. Order History & Downloads (`OrdersListScreen`)

* Displays complete transaction history of purchased digital goods.
* Shows license keys, purchase timestamps, and order status pills (Completed, Pending, Refunded).
* Secure 1-tap download link for purchased assets.

---

## 3. Secure Billing Redirection Policy

To strictly adhere to Google Play Developer Distribution Agreements and protect sensitive payment data:
* Subscriptions and real-currency transactions are **never processed inside unverified native text fields**.
* When tapping **"Upgrade to Gold / Diamond"**, the app safely launches the backend's checkout page in the system browser via `SafeUrlLauncher`:

```dart
SafeUrlLauncher.launchSafely('${dotenv.env['BASE_URL']}/billing/checkout?plan_id=$planId');
```
