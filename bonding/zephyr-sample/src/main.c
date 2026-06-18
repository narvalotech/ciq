#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/byteorder.h>
#include <zephyr/kernel.h>
#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/hci.h>
#include <zephyr/bluetooth/gatt.h>
#include <zephyr/settings/settings.h>
#include <zephyr/random/random.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

/* Temperature is in hundredths of a degree Celsius (24.5 degrees) */
static int16_t temperature = 2450;
static struct bt_conn *current_conn;
static bool subscribed = false;

static void temp_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value) {
	bool notify_enabled = (value == BT_GATT_CCC_NOTIFY);
	LOG_INF("Temperature notifications %s", notify_enabled ? "enabled" : "disabled");
	subscribed = notify_enabled;
}

static ssize_t read_temperature(struct bt_conn *conn, const struct bt_gatt_attr *attr,
								void *buf, uint16_t len, uint16_t offset) {
	const int16_t *value = attr->user_data;
	int16_t temp_le = sys_cpu_to_le16(*value);
	return bt_gatt_attr_read(conn, attr, buf, len, offset, &temp_le, sizeof(temp_le));
}

/* Environmental Sensing Service */
BT_GATT_SERVICE_DEFINE(ess_svc,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_ESS),
	BT_GATT_CHARACTERISTIC(BT_UUID_TEMPERATURE,
						   BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
						   BT_GATT_PERM_READ_ENCRYPT,
						   read_temperature, NULL, &temperature),
	BT_GATT_CCC(temp_ccc_cfg_changed, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE | BT_GATT_PERM_WRITE_ENCRYPT)
);

static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA_BYTES(BT_DATA_GAP_APPEARANCE, 0x00, 0x03), /* 768 or 0x0300 Generic Thermometer */
	BT_DATA_BYTES(BT_DATA_UUID16_ALL, BT_UUID_16_ENCODE(BT_UUID_ESS_VAL)),
	BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME, sizeof(CONFIG_BT_DEVICE_NAME) - 1)
};

static void connected(struct bt_conn *conn, uint8_t err) {
	if (err) {
		LOG_ERR("Connection failed (err %u)", err);
	} else {
		LOG_INF("Connection from peer established");
		current_conn = bt_conn_ref(conn);
	}
}

static void disconnected(struct bt_conn *conn, uint8_t reason) {
	LOG_INF("Disconnected (reason %u)", reason);
	if (current_conn) {
		bt_conn_unref(current_conn);
		current_conn = NULL;
		subscribed = false;
	}
}

static void security_changed(struct bt_conn *conn, bt_security_t level, enum bt_security_err err) {
	if (!err) {
		LOG_INF("Secure connection established (level %u)", level);
	} else {
		LOG_ERR("Security failed: err %u", err);
	}
}

BT_CONN_CB_DEFINE(conn_callbacks) = {
	.connected = connected,
	.disconnected = disconnected,
	.security_changed = security_changed,
};

static void auth_pairing_complete(struct bt_conn *conn, bool bonded) {
	LOG_INF("Pairing complete, bonded: %s", bonded ? "yes" : "no");
}

static void auth_pairing_failed(struct bt_conn *conn, enum bt_security_err reason) {
	LOG_ERR("Pairing failed (reason %d)", reason);

	int err = bt_unpair(BT_ID_DEFAULT, bt_conn_get_dst(conn));
	if (err) {
		LOG_ERR("Failed to clear bond: %d", err);
	} else {
		LOG_INF("Bond cleared successfully. Ready for repair.");
	}
}

static struct bt_conn_auth_info_cb auth_info_cb_info = {
	.pairing_complete = auth_pairing_complete,
	.pairing_failed = auth_pairing_failed,
};

/* Using "Just Works" pairing with LE Secure Connections */
static const struct bt_conn_auth_cb auth_cb_display = {
	.cancel = NULL,
};

static void simulate_sensor_work_handler(struct k_work *work) {
	/* Fluctuate temperature by a small random amount (-50 to +50 hundredths) */
	temperature += (sys_rand32_get() % 100) - 50;

	if (current_conn && subscribed) {
		int16_t temp_le = sys_cpu_to_le16(temperature);
		bt_gatt_notify(current_conn, &ess_svc.attrs[1], &temp_le, sizeof(temp_le));
		LOG_INF("Notified temp: %d", temperature);
	}

	if (!current_conn) {
		int err = bt_le_adv_start(BT_LE_ADV_CONN_FAST_1, ad, ARRAY_SIZE(ad), NULL, 0);
		if (err && err != -120) {
			LOG_ERR("Advertising failed to start (err %d)", err);
		}
	}
}

K_WORK_DEFINE(sensor_work, simulate_sensor_work_handler);

static void sensor_timer_handler(struct k_timer *timer) {
	k_work_submit(&sensor_work);
}

K_TIMER_DEFINE(sensor_timer, sensor_timer_handler, NULL);

int main(void) {
	int err;

	LOG_INF("Starting Zephyr BLE Temperature Peripheral");

	bt_conn_auth_cb_register(&auth_cb_display);
	bt_conn_auth_info_cb_register(&auth_info_cb_info);

	err = bt_enable(NULL);
	if (err) {
		LOG_ERR("Bluetooth init failed (err %d)", err);
		return 0;
	}

	LOG_INF("Bluetooth initialized");

	if (IS_ENABLED(CONFIG_SETTINGS)) {
		settings_load();
	}

	err = bt_le_adv_start(BT_LE_ADV_CONN_FAST_1, ad, ARRAY_SIZE(ad), NULL, 0);
	if (err) {
		LOG_ERR("Advertising failed to start (err %d)", err);
		return 0;
	}

	LOG_INF("Advertising successfully started");

	k_timer_start(&sensor_timer, K_SECONDS(1), K_SECONDS(1));

	return 0;
}
