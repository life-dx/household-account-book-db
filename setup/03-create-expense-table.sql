CREATE SCHEMA IF NOT EXISTS expense;

CREATE TABLE IF NOT EXISTS expense.expense_headers (
    expense_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    group_id uuid NOT NULL REFERENCES user.groups(group_id) ON DELETE CASCADE,
    expense_date date NOT NULL,
    expense_title varchar(255) NOT NULL,
    invoice_rate smallint NOT NULL,
    expensed_by uuid NOT NULL REFERENCES user.accounts(user_id) ON DELETE CASCADE,
    created_by uuid NOT NULL REFERENCES user.accounts(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fixed boolean NOT NULL DEFAULT false,
    file_path VARCHAR(255),
    file_hash VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS expense.categories (
    category_id varchar(50) PRIMARY KEY,
    display_name varchar(50) NOT NULL,
    display_color varchar(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS expense.standard_items (
    item_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    item_name varchar(255) NOT NULL,
    price integer NULL,
    category_id varchar(50) NOT NULL REFERENCES expense.categories(category_id) ON DELETE
);

CREATE TABLE IF NOT EXISTS expense.expense_rules (
    rule_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    group_id uuid NOT NULL REFERENCES user.groups(group_id) ON DELETE CASCADE,
    rule_name varchar(255) NOT NULL,
    behavior_code smallint NOT NULL,
    notify_to uuid NOT NULL REFERENCES user.accounts(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by uuid NOT NULL REFERENCES user.accounts(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS expense.expense_bodies (
    expense_id uuid NOT NULL REFERENCES expense.expense_headers(expense_id) ON DELETE CASCADE,
    item_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    item_name varchar(255) NOT NULL,
    price integer NOT NULL,
    category_id varchar(50) NOT NULL REFERENCES expense.categories(category_id) ON DELETE
    quantity integer NOT NULL DEFAULT 1,
    rule_id uuid REFERENCES expense.expense_rules(rule_id) ON DELETE SET NULL,
    fixed boolean NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS expense.confirm_histories (
    expense_id uuid NOT NULL REFERENCES expense.expense_headers(expense_id) ON DELETE CASCADE,
    confirmed boolean NOT NULL,
    confirmed_by uuid NOT NULL REFERENCES user.accounts(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    forced boolean NOT NULL DEFAULT false
);

CREATE VIEW IF NOT EXISTS expense.v_confirm_status AS
SELECT
    eh.expense_id,
    eh.expense_title,
    eh.expense_date,
    eh.group_id,
    eh.expensed_by,
    ech.confirmed,
    ech.confirmed_by,
    ech.created_at AS confirmed_at
FROM
    expense.expense_headers eh
LEFT JOIN (
    SELECT DISTINCT ON (expense_id) *
    FROM expense.expense_confirm_histories
    ORDER BY expense_id, created_at DESC
) ech ON eh.expense_id = ech.expense_id;

CREATE TABLE IF NOT EXISTS expense.aggregate_histories (
    aggregate_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    file_path VARCHAR(255),
    file_hash VARCHAR(255)
);

CREATE TRIGGER update_expense_headers_modtime
BEFORE UPDATE ON expense.expense_headers
FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();

CREATE TRIGGER update_expense_bodies_modtime
BEFORE UPDATE ON expense.expense_bodies
FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();

CREATE TRIGGER update_expense_rules_modtime
BEFORE UPDATE ON expense.expense_rules
FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();