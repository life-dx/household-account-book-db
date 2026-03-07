
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.accounts (
    user_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    google_sub varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    name varchar(255) NOT NULL,
    picture_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth.groups (
    group_id uuid PRIMARY KEY NOT NULL DEFAULT uuidv7(),
    group_name varchar(255) NOT NULL,
    description TEXT,
    user_id_1 uuid NOT NULL REFERENCES auth.accounts(user_id) ON DELETE CASCADE,
    user_id_2 uuid NOT NULL REFERENCES auth.accounts(user_id) ON DELETE CASCADE,
    active boolean NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- アクティブなグループのみを表示するビュー
CREATE OR REPLACE VIEW auth.v_active_groups AS
SELECT group_id, group_name, description, user_id_1, user_id_2, created_at
FROM auth.groups
WHERE active = true;

CREATE TABLE IF NOT EXISTS auth.user_contacts (
    user_id uuid PRIMARY KEY NOT NULL REFERENCES auth.accounts(user_id) ON DELETE CASCADE,
    line_user_id varchar(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TRIGGER update_user_accounts_modtime
BEFORE UPDATE ON auth.accounts
FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();

CREATE TRIGGER update_user_contacts_modtime
BEFORE UPDATE ON auth.user_contacts
FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();