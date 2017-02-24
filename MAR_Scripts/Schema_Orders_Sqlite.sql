CREATE TABLE IF NOT EXISTS enum_exn_type (id INTEGER NOT NULL UNIQUE PRIMARY KEY, name TEXT);
INSERT OR IGNORE INTO enum_exn_type VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_exn_type VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_exn_type VALUES (1, 'USA § 988(a)(1)(B)');

CREATE TABLE IF NOT EXISTS enum_spt_phase (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_spt_phase VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_spt_phase VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_spt_phase VALUES (1, 'Entry');
INSERT OR IGNORE INTO enum_spt_phase VALUES (2, 'Exit');

CREATE TABLE IF NOT EXISTS enum_spt_subtype (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_spt_subtype VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (1, 'Commission');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (2, 'Swap');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (3, 'Tax');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (4, 'Deposit');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (5, 'Withdrawal');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (6, 'Expense');
INSERT OR IGNORE INTO enum_spt_subtype VALUES (7, 'Rebate');

CREATE TABLE IF NOT EXISTS enum_spt_type (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_spt_type VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_spt_type VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_spt_type VALUES (1, 'Gross');
INSERT OR IGNORE INTO enum_spt_type VALUES (2, 'Fee');
INSERT OR IGNORE INTO enum_spt_type VALUES (3, 'Adjustment');

CREATE TABLE IF NOT EXISTS enum_txn_type (id INT PRIMARY KEY NOT NULL UNIQUE, name TEXT);
INSERT OR IGNORE INTO enum_txn_type VALUES (-1, 'Unspecified');
INSERT OR IGNORE INTO enum_txn_type VALUES (0, 'Other');
INSERT OR IGNORE INTO enum_txn_type VALUES (1, 'Short');
INSERT OR IGNORE INTO enum_txn_type VALUES (2, 'Long');
INSERT OR IGNORE INTO enum_txn_type VALUES (3, 'Balance');

CREATE TABLE IF NOT EXISTS accounts (guid TEXT PRIMARY KEY UNIQUE NOT NULL, num INT NOT NULL, name TEXT);

CREATE TABLE IF NOT EXISTS currency (guid TEXT PRIMARY KEY UNIQUE NOT NULL, name TEXT NOT NULL, fraction DOUBLE NOT NULL DEFAULT (1));

CREATE TABLE IF NOT EXISTS elections (guid TEXT PRIMARY KEY UNIQUE NOT NULL, txn_guid TEXT NOT NULL, type INTEGER NOT NULL DEFAULT (- 1), active BOOLEAN NOT NULL DEFAULT false, made_datetime DATETIME NOT NULL, recorded_datetime DATETIME NOT NULL);

CREATE TABLE IF NOT EXISTS splits (guid TEXT PRIMARY KEY UNIQUE NOT NULL, txn_guid TEXT NOT NULL, cny_guid TEXT NOT NULL, phase INTEGER NOT NULL DEFAULT (- 1), type INTEGER NOT NULL DEFAULT (- 1), subtype INTEGER NOT NULL DEFAULT (- 1), amount DOUBLE NOT NULL, comment TEXT);

CREATE TABLE IF NOT EXISTS transactions (guid TEXT PRIMARY KEY UNIQUE NOT NULL, act_guid TEXT NOT NULL, type INTEGER NOT NULL DEFAULT (- 1), num INT NOT NULL, comment TEXT, magic INTEGER DEFAULT (- 1) NOT NULL, entry_datetime DATETIME NOT NULL);

CREATE TABLE IF NOT EXISTS txn_orders (txn_guid TEXT PRIMARY KEY UNIQUE NOT NULL, symbol TEXT NOT NULL, lots DOUBLE NOT NULL, exit_datetime DATETIME, entry_pips DOUBLE NOT NULL, exit_pips DOUBLE);
