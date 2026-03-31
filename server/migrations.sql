 -- This file provides a method for applying incremental schema changes
-- to a PostgreSQL database.

-- Add your migrations at the end of the file, and run "psql -v ON_ERROR_STOP=1 -1f
-- migrations.sql yourdbname" to apply all pending migrations. The
-- "-1" causes all the changes to be applied atomically

-- Most Rails (ie. ActiveRecord) migrations are run by a user with
-- full read-write access to both the schema and its contents, which
-- isn't ideal. You'd generally run this file as a database owner, and
-- the contained migrations would grant access to less-privileged
-- application-level users as appropriate.

-- Refer to https://github.com/purcell/postgresql-migrations for info and updates

--------------------------------------------------------------------------------
-- A function that will apply an individual migration
--------------------------------------------------------------------------------
DO
$body$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_proc WHERE proname = 'apply_migration') THEN
    CREATE FUNCTION apply_migration (migration_name TEXT, ddl TEXT) RETURNS BOOLEAN
      AS $$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_catalog.pg_tables WHERE tablename = 'applied_migrations') THEN
        CREATE TABLE applied_migrations (
            identifier TEXT NOT NULL PRIMARY KEY
          , ddl TEXT NOT NULL
          , applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
        );
      END IF;
      LOCK TABLE applied_migrations IN EXCLUSIVE MODE;
      IF NOT EXISTS (SELECT 1 FROM applied_migrations m WHERE m.identifier = migration_name)
      THEN
        RAISE NOTICE 'Applying migration: %', migration_name;
        EXECUTE ddl;
        INSERT INTO applied_migrations (identifier, ddl) VALUES (migration_name, ddl);
        RETURN TRUE;
      END IF;
      RETURN FALSE;
    END;
    $$ LANGUAGE plpgsql;
  END IF;
END
$body$;

--------------------------------------------------------------------------------
-- Lots of migrations removed
--------------------------------------------------------------------------------


-- make hash and image_url not required on asset_library table

select apply_migration('make-hash-and-image-url-not-required-on-asset-library-table',
$$
  ALTER TABLE asset_library ALTER COLUMN hash DROP NOT NULL;
  ALTER TABLE asset_library ALTER COLUMN image_url DROP NOT NULL;
  ALTER TABLE asset_library ALTER COLUMN id DROP DEFAULT;
$$
);



-- add lightmap_url to properties table
select apply_migration('add-lightmap-url-to-properties-table',
$$
  ALTER TABLE properties ADD COLUMN lightmap_url TEXT;

  UPDATE properties
  SET lightmap_url = content->>'lightmap_url';

  ALTER TABLE properties DROP COLUMN lightmap_status;

  UPDATE properties
  SET content = (content::jsonb - 'lightmap_url')::json;
$$
);


-- add lightmap_url to properties table
select apply_migration('add-lightmap-url-to-properties-table-2',
$$
  ALTER TABLE properties ADD COLUMN lightmap_url TEXT;

  UPDATE properties
  SET lightmap_url = content->>'lightmap_url';

  ALTER TABLE properties DROP COLUMN lightmap_status;

$$
);



-- add lightmap_url to spaces table
select apply_migration('add-lightmap-url-to-spaces-table',
$$
  ALTER TABLE spaces ADD COLUMN lightmap_url TEXT;

  UPDATE spaces
  SET lightmap_url = content->>'lightmap_url';

  ALTER TABLE spaces DROP COLUMN lightmap_status;

$$
);


-- correct search_corpus materialized view definition to fix avatar search and maybe even wearable search
-- migration that created the materialized view was lost, but I found it here: https://github.com/cryptovoxels/cryptovoxels/commit/95b025131806a2978c4aa10996710fff81ad89fe#diff-c2b7b39dbd96e99076d33a8af4c00e01daa8829403a11626797ebc2bac123c9d
select apply_migration('correct-search-corpus-materialized-view-definition',
$$
  DROP MATERIALIZED VIEW search_corpus;
  CREATE MATERIALIZED VIEW search_corpus AS
    WITH src AS (
      SELECT p.id::text                     AS id,
            COALESCE(p.name, p.address)    AS title,
            p.id::text                     AS description, -- parcel id as description so we can find it by id
            p.minted_at                    AS created_at,
            'parcel'                       AS kind
      FROM   properties p
      WHERE  (p.minted OR p.is_common)

      UNION ALL
      SELECT w.id::text, w.name, w.description, w.created_at, 'wearable'
      FROM   wearables w

      UNION ALL
      SELECT av.owner as id, COALESCE(av.name, av.owner::text), (CASE WHEN av.name IS NOT NULL THEN av.owner ELSE NULL END), av.created_at, 'avatar'
      FROM   avatars av

      UNION ALL
      SELECT s.id::text, s.name, NULL, s.created_at, 'space'
      FROM   spaces s
      WHERE  s.unlisted IS DISTINCT FROM true

      UNION ALL
      SELECT al.id::text, al.name, al.description, al.created_at, 'asset'
      FROM   asset_library al
  )
  SELECT *,
        setweight(to_tsvector('english', title), 'A') ||
        setweight(to_tsvector('english', COALESCE(description, '')), 'B')
        AS search_tsv         -- ← computed once during REFRESH
  FROM   src;

$$
);