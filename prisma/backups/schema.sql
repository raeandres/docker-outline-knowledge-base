


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."enum_file_operations_state" AS ENUM (
    'creating',
    'uploading',
    'complete',
    'error',
    'expired'
);


ALTER TYPE "public"."enum_file_operations_state" OWNER TO "postgres";


CREATE TYPE "public"."enum_file_operations_type" AS ENUM (
    'import',
    'export'
);


ALTER TYPE "public"."enum_file_operations_type" OWNER TO "postgres";


CREATE TYPE "public"."enum_group_users_permission" AS ENUM (
    'admin',
    'member'
);


ALTER TYPE "public"."enum_group_users_permission" OWNER TO "postgres";


CREATE TYPE "public"."enum_relationships_type" AS ENUM (
    'backlink',
    'similar'
);


ALTER TYPE "public"."enum_relationships_type" OWNER TO "postgres";


CREATE TYPE "public"."enum_search_queries_source" AS ENUM (
    'slack',
    'app',
    'api',
    'oauth'
);


ALTER TYPE "public"."enum_search_queries_source" OWNER TO "postgres";


CREATE TYPE "public"."enum_users_role" AS ENUM (
    'admin',
    'member',
    'viewer',
    'guest'
);


ALTER TYPE "public"."enum_users_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atlases_search_trigger"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new."searchVector" :=
    setweight(to_tsvector('english', coalesce(new.name, '')),'A') ||
    setweight(to_tsvector('english', coalesce(new.description, '')), 'C');
  return new;
end
$$;


ALTER FUNCTION "public"."atlases_search_trigger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."documents_search_trigger"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
    begin
      new."searchVector" :=
        setweight(to_tsvector('english', coalesce(new.title, '')),'A') ||
        setweight(to_tsvector('english', coalesce(array_to_string(new."previousTitles", ' , '),'')),'C') ||
        setweight(to_tsvector('english', substring(coalesce(new.text, ''), 1, 1000000)), 'D');
      return new;
    end
    $$;


ALTER FUNCTION "public"."documents_search_trigger"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."SequelizeMeta" (
    "name" character varying(255) NOT NULL
);


ALTER TABLE "public"."SequelizeMeta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."apiKeys" (
    "id" "uuid" NOT NULL,
    "name" character varying,
    "secret" character varying(255),
    "userId" "uuid",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "expiresAt" timestamp with time zone,
    "lastActiveAt" timestamp with time zone,
    "hash" character varying(255),
    "last4" character varying(4),
    "scope" character varying(255)[]
);


ALTER TABLE "public"."apiKeys" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."attachments" (
    "id" "uuid" NOT NULL,
    "teamId" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "documentId" "uuid",
    "key" character varying(4096) NOT NULL,
    "contentType" character varying(255) NOT NULL,
    "size" bigint NOT NULL,
    "acl" character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "lastAccessedAt" timestamp with time zone,
    "expiresAt" timestamp with time zone
);


ALTER TABLE "public"."attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."authentication_providers" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "providerId" character varying(255) NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."authentication_providers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."authentications" (
    "id" "uuid" NOT NULL,
    "userId" "uuid",
    "teamId" "uuid",
    "service" character varying(255) NOT NULL,
    "token" "bytea",
    "scopes" character varying(255)[],
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "refreshToken" "bytea",
    "expiresAt" timestamp with time zone
);


ALTER TABLE "public"."authentications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."relationships" (
    "id" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "documentId" "uuid" NOT NULL,
    "reverseDocumentId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "type" "public"."enum_relationships_type" DEFAULT 'backlink'::"public"."enum_relationships_type" NOT NULL
);


ALTER TABLE "public"."relationships" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."backlinks" AS
 SELECT "id",
    "userId",
    "documentId",
    "reverseDocumentId",
    "createdAt",
    "updatedAt"
   FROM "public"."relationships"
  WHERE ("type" = 'backlink'::"public"."enum_relationships_type");


ALTER VIEW "public"."backlinks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_permissions" (
    "collectionId" "uuid",
    "groupId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "permission" character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "documentId" "uuid",
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "sourceId" "uuid"
);


ALTER TABLE "public"."group_permissions" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."collection_groups" AS
 SELECT "collectionId",
    "groupId",
    "createdById",
    "permission",
    "createdAt",
    "updatedAt",
    "deletedAt",
    "documentId"
   FROM "public"."group_permissions";


ALTER VIEW "public"."collection_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_permissions" (
    "collectionId" "uuid",
    "userId" "uuid" NOT NULL,
    "permission" character varying(255) DEFAULT 'read_write'::character varying NOT NULL,
    "createdById" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "documentId" "uuid",
    "index" character varying(255),
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "sourceId" "uuid"
);


ALTER TABLE "public"."user_permissions" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."collection_users" AS
 SELECT "collectionId",
    "userId",
    "permission",
    "createdById",
    "createdAt",
    "updatedAt",
    "documentId"
   FROM "public"."user_permissions";


ALTER VIEW "public"."collection_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collections" (
    "id" "uuid" NOT NULL,
    "name" character varying,
    "description" character varying,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "teamId" "uuid" NOT NULL,
    "searchVector" "tsvector",
    "createdById" "uuid",
    "deletedAt" timestamp with time zone,
    "urlId" character varying(255),
    "documentStructure" "jsonb",
    "color" "text",
    "maintainerApprovalRequired" boolean DEFAULT false NOT NULL,
    "icon" "text",
    "sort" "jsonb",
    "sharing" boolean DEFAULT true NOT NULL,
    "index" "text",
    "permission" character varying(255) DEFAULT NULL::character varying,
    "state" "bytea",
    "importId" "uuid",
    "content" "jsonb",
    "archivedAt" timestamp with time zone,
    "archivedById" "uuid",
    "apiImportId" "uuid",
    "commenting" boolean,
    "sourceMetadata" "jsonb"
);


ALTER TABLE "public"."collections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" "uuid" NOT NULL,
    "data" "jsonb" NOT NULL,
    "documentId" "uuid" NOT NULL,
    "parentCommentId" "uuid",
    "createdById" "uuid" NOT NULL,
    "resolvedAt" timestamp with time zone,
    "resolvedById" "uuid",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "reactions" "jsonb"
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."documents" (
    "id" "uuid" NOT NULL,
    "urlId" character varying NOT NULL,
    "title" character varying NOT NULL,
    "text" "text",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "collectionId" "uuid",
    "teamId" "uuid",
    "parentDocumentId" "uuid",
    "lastModifiedById" "uuid" NOT NULL,
    "revisionCount" integer DEFAULT 0,
    "searchVector" "tsvector",
    "deletedAt" timestamp with time zone,
    "createdById" "uuid",
    "collaboratorIds" "uuid"[],
    "publishedAt" timestamp with time zone,
    "pinnedById" "uuid",
    "archivedAt" timestamp with time zone,
    "isWelcome" boolean DEFAULT false NOT NULL,
    "editorVersion" character varying(255),
    "version" smallint,
    "template" boolean DEFAULT false NOT NULL,
    "templateId" "uuid",
    "previousTitles" character varying(255)[],
    "state" "bytea",
    "fullWidth" boolean DEFAULT false NOT NULL,
    "importId" "uuid",
    "insightsEnabled" boolean DEFAULT true NOT NULL,
    "sourceMetadata" "jsonb",
    "content" "jsonb",
    "summary" "text",
    "icon" character varying(255),
    "color" character varying(255),
    "apiImportId" "uuid",
    "language" character varying(2),
    "popularityScore" double precision DEFAULT '0'::double precision NOT NULL
);


ALTER TABLE "public"."documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."emojis" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "attachmentId" "uuid" NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."emojis" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "data" "jsonb",
    "userId" "uuid",
    "collectionId" "uuid",
    "teamId" "uuid",
    "createdAt" timestamp with time zone NOT NULL,
    "documentId" "uuid",
    "actorId" "uuid",
    "modelId" "uuid",
    "ip" character varying(255),
    "changes" "jsonb",
    "authType" character varying(255)
);


ALTER TABLE "public"."events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."file_operations" (
    "id" "uuid" NOT NULL,
    "state" "public"."enum_file_operations_state" NOT NULL,
    "type" "public"."enum_file_operations_type" NOT NULL,
    "key" character varying(255),
    "url" character varying(255),
    "size" bigint NOT NULL,
    "userId" "uuid" NOT NULL,
    "collectionId" "uuid",
    "teamId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "error" character varying(255),
    "format" character varying(255) DEFAULT 'outline-markdown'::character varying NOT NULL,
    "includeAttachments" boolean DEFAULT true NOT NULL,
    "deletedAt" timestamp with time zone,
    "options" "jsonb",
    "documentId" "uuid"
);


ALTER TABLE "public"."file_operations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_users" (
    "userId" "uuid" NOT NULL,
    "groupId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "permission" "public"."enum_group_users_permission" DEFAULT 'member'::"public"."enum_group_users_permission" NOT NULL
);


ALTER TABLE "public"."group_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."groups" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "externalId" character varying(255),
    "disableMentions" boolean DEFAULT false NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."import_tasks" (
    "id" "uuid" NOT NULL,
    "state" character varying(255) NOT NULL,
    "input" "jsonb" NOT NULL,
    "output" "jsonb",
    "importId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "error" character varying(255)
);


ALTER TABLE "public"."import_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."imports" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "service" character varying(255) NOT NULL,
    "state" character varying(255) NOT NULL,
    "input" "jsonb" NOT NULL,
    "documentCount" integer DEFAULT 0 NOT NULL,
    "integrationId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "error" character varying(255)
);


ALTER TABLE "public"."imports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."integrations" (
    "id" "uuid" NOT NULL,
    "type" character varying(255),
    "userId" "uuid",
    "teamId" "uuid" NOT NULL,
    "service" character varying(255) NOT NULL,
    "collectionId" "uuid",
    "authenticationId" "uuid",
    "events" character varying(255)[],
    "settings" "jsonb",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "issueSources" "jsonb"
);


ALTER TABLE "public"."integrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" NOT NULL,
    "actorId" "uuid",
    "userId" "uuid" NOT NULL,
    "event" character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "viewedAt" timestamp with time zone,
    "emailedAt" timestamp with time zone,
    "teamId" "uuid" NOT NULL,
    "documentId" "uuid",
    "commentId" "uuid",
    "revisionId" "uuid",
    "collectionId" "uuid",
    "archivedAt" timestamp with time zone,
    "membershipId" "uuid",
    "data" json,
    "groupId" "uuid"
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oauth_authentications" (
    "id" "uuid" NOT NULL,
    "accessTokenHash" character varying(255) NOT NULL,
    "accessTokenExpiresAt" timestamp with time zone NOT NULL,
    "refreshTokenHash" character varying(255) NOT NULL,
    "refreshTokenExpiresAt" timestamp with time zone NOT NULL,
    "lastActiveAt" timestamp with time zone,
    "scope" character varying(255)[] NOT NULL,
    "oauthClientId" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "grantId" "uuid"
);


ALTER TABLE "public"."oauth_authentications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oauth_authorization_codes" (
    "id" "uuid" NOT NULL,
    "authorizationCodeHash" character varying(255) NOT NULL,
    "codeChallenge" character varying(255),
    "codeChallengeMethod" character varying(255),
    "scope" character varying(255)[] NOT NULL,
    "oauthClientId" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "redirectUri" character varying(255) NOT NULL,
    "expiresAt" timestamp with time zone NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "grantId" "uuid"
);


ALTER TABLE "public"."oauth_authorization_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oauth_clients" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "description" character varying(255),
    "developerName" character varying(255),
    "developerUrl" character varying(255),
    "avatarUrl" character varying(255),
    "clientId" character varying(255) NOT NULL,
    "clientSecret" "bytea" NOT NULL,
    "published" boolean DEFAULT false NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "redirectUris" character varying(255)[] DEFAULT (ARRAY[]::character varying[])::character varying(255)[] NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "clientType" character varying(255) DEFAULT 'confidential'::character varying NOT NULL
);


ALTER TABLE "public"."oauth_clients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pins" (
    "id" "uuid" NOT NULL,
    "documentId" "uuid" NOT NULL,
    "collectionId" "uuid",
    "teamId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "index" character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."pins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reactions" (
    "id" "uuid" NOT NULL,
    "emoji" character varying(255) NOT NULL,
    "userId" "uuid" NOT NULL,
    "commentId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."reactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."revisions" (
    "id" "uuid" NOT NULL,
    "title" character varying NOT NULL,
    "text" "text",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "userId" "uuid" NOT NULL,
    "documentId" "uuid" NOT NULL,
    "editorVersion" character varying(255),
    "version" smallint,
    "content" "jsonb",
    "icon" character varying(255),
    "color" character varying(255),
    "name" character varying(255),
    "deletedAt" timestamp with time zone,
    "collaboratorIds" "uuid"[] DEFAULT ARRAY[]::"uuid"[] NOT NULL
);


ALTER TABLE "public"."revisions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."search_queries" (
    "id" "uuid" NOT NULL,
    "userId" "uuid",
    "teamId" "uuid",
    "source" "public"."enum_search_queries_source" NOT NULL,
    "query" character varying(255) NOT NULL,
    "results" integer NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "shareId" "uuid",
    "score" integer,
    "answer" "text"
);


ALTER TABLE "public"."search_queries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shares" (
    "id" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "teamId" "uuid" NOT NULL,
    "documentId" "uuid",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "revokedAt" timestamp with time zone,
    "revokedById" "uuid",
    "published" boolean DEFAULT false NOT NULL,
    "lastAccessedAt" timestamp with time zone,
    "includeChildDocuments" boolean DEFAULT false NOT NULL,
    "views" integer DEFAULT 0,
    "urlId" character varying(255),
    "domain" character varying(255),
    "allowIndexing" boolean DEFAULT true NOT NULL,
    "showLastUpdated" boolean DEFAULT false NOT NULL,
    "collectionId" "uuid",
    "showTOC" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."shares" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stars" (
    "id" "uuid" NOT NULL,
    "documentId" "uuid",
    "userId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "index" character varying(255),
    "collectionId" "uuid"
);


ALTER TABLE "public"."stars" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "documentId" "uuid",
    "event" character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "collectionId" "uuid"
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."team_domains" (
    "id" "uuid" NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."team_domains" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "avatarUrl" character varying(4096),
    "deletedAt" timestamp with time zone,
    "sharing" boolean DEFAULT true NOT NULL,
    "subdomain" character varying(255),
    "documentEmbeds" boolean DEFAULT true NOT NULL,
    "guestSignin" boolean DEFAULT false NOT NULL,
    "domain" character varying(255),
    "signupQueryParams" "jsonb",
    "collaborativeEditing" boolean,
    "defaultUserRole" character varying(255) DEFAULT 'member'::character varying NOT NULL,
    "defaultCollectionId" "uuid",
    "memberCollectionCreate" boolean DEFAULT true NOT NULL,
    "inviteRequired" boolean DEFAULT false NOT NULL,
    "preferences" "jsonb",
    "suspendedAt" timestamp with time zone,
    "lastActiveAt" timestamp with time zone,
    "memberTeamCreate" boolean DEFAULT true NOT NULL,
    "approximateTotalAttachmentsSize" bigint DEFAULT 0,
    "previousSubdomains" character varying(255)[],
    "description" "text",
    "passkeysEnabled" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."teams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_authentications" (
    "id" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "authenticationProviderId" "uuid" NOT NULL,
    "accessToken" "bytea",
    "refreshToken" "bytea",
    "scopes" character varying(255)[],
    "providerId" character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "expiresAt" timestamp with time zone,
    "lastValidatedAt" timestamp with time zone
);


ALTER TABLE "public"."user_authentications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_passkeys" (
    "id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "userAgent" "text",
    "credentialId" "text" NOT NULL,
    "credentialPublicKey" "bytea" NOT NULL,
    "aaguid" "text",
    "counter" bigint DEFAULT 0 NOT NULL,
    "transports" character varying(255)[],
    "lastActiveAt" timestamp with time zone,
    "userId" "uuid" NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."user_passkeys" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" character varying(255) DEFAULT NULL::character varying,
    "name" character varying NOT NULL,
    "jwtSecret" "bytea",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "teamId" "uuid",
    "avatarUrl" character varying(4096),
    "suspendedById" "uuid",
    "suspendedAt" timestamp with time zone,
    "lastActiveAt" timestamp with time zone,
    "lastActiveIp" character varying(255),
    "lastSignedInAt" timestamp with time zone,
    "lastSignedInIp" character varying(255),
    "deletedAt" timestamp with time zone,
    "lastSigninEmailSentAt" timestamp with time zone,
    "language" character varying(255) DEFAULT 'en_US'::character varying,
    "flags" "jsonb",
    "invitedById" "uuid",
    "preferences" "jsonb",
    "notificationSettings" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "role" "public"."enum_users_role" NOT NULL,
    "timezone" character varying(255)
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."views" (
    "id" "uuid" NOT NULL,
    "documentId" "uuid" NOT NULL,
    "userId" "uuid" NOT NULL,
    "count" integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "lastEditingAt" timestamp with time zone
);


ALTER TABLE "public"."views" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."webhook_deliveries" (
    "id" "uuid" NOT NULL,
    "webhookSubscriptionId" "uuid" NOT NULL,
    "status" character varying(255) NOT NULL,
    "statusCode" integer,
    "requestBody" "jsonb",
    "requestHeaders" "jsonb",
    "responseBody" "text",
    "responseHeaders" "jsonb",
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."webhook_deliveries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."webhook_subscriptions" (
    "id" "uuid" NOT NULL,
    "teamId" "uuid" NOT NULL,
    "createdById" "uuid" NOT NULL,
    "url" character varying(255) NOT NULL,
    "enabled" boolean NOT NULL,
    "name" character varying(255) NOT NULL,
    "events" character varying(255)[] NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    "secret" "bytea"
);


ALTER TABLE "public"."webhook_subscriptions" OWNER TO "postgres";


ALTER TABLE ONLY "public"."SequelizeMeta"
    ADD CONSTRAINT "SequelizeMeta_pkey" PRIMARY KEY ("name");



ALTER TABLE ONLY "public"."apiKeys"
    ADD CONSTRAINT "apiKeys_hash_key" UNIQUE ("hash");



ALTER TABLE ONLY "public"."apiKeys"
    ADD CONSTRAINT "apiKeys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."apiKeys"
    ADD CONSTRAINT "apiKeys_secret_key" UNIQUE ("secret");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "atlases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "atlases_urlId_key" UNIQUE ("urlId");



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."authentication_providers"
    ADD CONSTRAINT "authentication_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."authentication_providers"
    ADD CONSTRAINT "authentication_providers_providerId_teamId_uk" UNIQUE ("providerId", "teamId");



ALTER TABLE ONLY "public"."authentications"
    ADD CONSTRAINT "authentications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "backlinks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_urlId_key" UNIQUE ("urlId");



ALTER TABLE ONLY "public"."emojis"
    ADD CONSTRAINT "emojis_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."file_operations"
    ADD CONSTRAINT "file_operations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_permissions"
    ADD CONSTRAINT "group_permissions_id_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_users"
    ADD CONSTRAINT "group_users_pkey" PRIMARY KEY ("groupId", "userId");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."import_tasks"
    ADD CONSTRAINT "import_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."imports"
    ADD CONSTRAINT "imports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oauth_authentications"
    ADD CONSTRAINT "oauth_authentications_accessTokenHash_key" UNIQUE ("accessTokenHash");



ALTER TABLE ONLY "public"."oauth_authentications"
    ADD CONSTRAINT "oauth_authentications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oauth_authentications"
    ADD CONSTRAINT "oauth_authentications_refreshTokenHash_key" UNIQUE ("refreshTokenHash");



ALTER TABLE ONLY "public"."oauth_authorization_codes"
    ADD CONSTRAINT "oauth_authorization_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_clientId_key" UNIQUE ("clientId");



ALTER TABLE ONLY "public"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reactions"
    ADD CONSTRAINT "reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."revisions"
    ADD CONSTRAINT "revisions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."search_queries"
    ADD CONSTRAINT "search_queries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_domain_key" UNIQUE ("domain");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stars"
    ADD CONSTRAINT "stars_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_domains"
    ADD CONSTRAINT "team_domains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_domain_key" UNIQUE ("domain");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_subdomain_key" UNIQUE ("subdomain");



ALTER TABLE ONLY "public"."user_authentications"
    ADD CONSTRAINT "user_authentications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_authentications"
    ADD CONSTRAINT "user_authentications_providerId_userId_uk" UNIQUE ("providerId", "userId");



ALTER TABLE ONLY "public"."user_passkeys"
    ADD CONSTRAINT "user_passkeys_credentialId_key" UNIQUE ("credentialId");



ALTER TABLE ONLY "public"."user_passkeys"
    ADD CONSTRAINT "user_passkeys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_permissions"
    ADD CONSTRAINT "user_permissions_id_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."views"
    ADD CONSTRAINT "views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhook_deliveries"
    ADD CONSTRAINT "webhook_deliveries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhook_subscriptions"
    ADD CONSTRAINT "webhook_subscriptions_pkey" PRIMARY KEY ("id");



CREATE INDEX "api_keys_user_id_deleted_at" ON "public"."apiKeys" USING "btree" ("userId", "deletedAt");



CREATE INDEX "attachments_created_at" ON "public"."attachments" USING "btree" ("createdAt");



CREATE INDEX "attachments_document_id" ON "public"."attachments" USING "btree" ("documentId");



CREATE INDEX "attachments_expires_at" ON "public"."attachments" USING "btree" ("expiresAt");



CREATE INDEX "attachments_team_id" ON "public"."attachments" USING "btree" ("teamId");



CREATE INDEX "authentication_providers_provider_id" ON "public"."authentication_providers" USING "btree" ("providerId");



CREATE INDEX "authentications_team_id_service" ON "public"."authentications" USING "btree" ("teamId", "service");



CREATE INDEX "backlinks_document_id" ON "public"."relationships" USING "btree" ("documentId");



CREATE INDEX "backlinks_reverse_document_id" ON "public"."relationships" USING "btree" ("reverseDocumentId");



CREATE INDEX "collections_api_import_id" ON "public"."collections" USING "btree" ("apiImportId");



CREATE INDEX "collections_archived_at" ON "public"."collections" USING "btree" ("archivedAt");



CREATE INDEX "collections_import_id" ON "public"."collections" USING "btree" ("importId");



CREATE INDEX "collections_team_id_deleted_at" ON "public"."collections" USING "btree" ("teamId", "deletedAt");



CREATE INDEX "comments_created_at" ON "public"."comments" USING "btree" ("createdAt");



CREATE INDEX "comments_document_id" ON "public"."comments" USING "btree" ("documentId");



CREATE INDEX "documents_api_import_id" ON "public"."documents" USING "btree" ("apiImportId");



CREATE INDEX "documents_archived_at" ON "public"."documents" USING "btree" ("archivedAt");



CREATE INDEX "documents_collection_id" ON "public"."documents" USING "btree" ("collectionId");



CREATE INDEX "documents_import_id" ON "public"."documents" USING "btree" ("importId");



CREATE INDEX "documents_parent_document_id_atlas_id_deleted_at" ON "public"."documents" USING "btree" ("parentDocumentId", "collectionId", "deletedAt");



CREATE INDEX "documents_published_at" ON "public"."documents" USING "btree" ("publishedAt");



CREATE INDEX "documents_team_id" ON "public"."documents" USING "btree" ("teamId", "deletedAt");



CREATE INDEX "documents_title_idx" ON "public"."documents" USING "gin" ("title" "public"."gin_trgm_ops");



CREATE INDEX "documents_tsv_idx" ON "public"."documents" USING "gin" ("searchVector");



CREATE INDEX "documents_updated_at" ON "public"."documents" USING "btree" ("updatedAt");



CREATE INDEX "documents_url_id_deleted_at" ON "public"."documents" USING "btree" ("urlId", "deletedAt");



CREATE INDEX "emojis_attachment_id" ON "public"."emojis" USING "btree" ("attachmentId");



CREATE INDEX "emojis_created_by_id" ON "public"."emojis" USING "btree" ("createdById");



CREATE INDEX "emojis_team_id" ON "public"."emojis" USING "btree" ("teamId");



CREATE UNIQUE INDEX "emojis_team_id_name" ON "public"."emojis" USING "btree" ("teamId", "name");



CREATE INDEX "events_actor_id" ON "public"."events" USING "btree" ("actorId");



CREATE INDEX "events_created_at" ON "public"."events" USING "btree" ("createdAt");



CREATE INDEX "events_document_id" ON "public"."events" USING "btree" ("documentId");



CREATE INDEX "events_name" ON "public"."events" USING "btree" ("name");



CREATE INDEX "events_team_id_collection_id" ON "public"."events" USING "btree" ("teamId", "collectionId");



CREATE INDEX "file_operations_type_state" ON "public"."file_operations" USING "btree" ("type", "state");



CREATE INDEX "group_permissions_collection_id_group_id" ON "public"."group_permissions" USING "btree" ("collectionId", "groupId");



CREATE INDEX "group_permissions_deleted_at" ON "public"."group_permissions" USING "btree" ("deletedAt");



CREATE INDEX "group_permissions_document_id" ON "public"."group_permissions" USING "btree" ("documentId");



CREATE INDEX "group_permissions_group_id" ON "public"."group_permissions" USING "btree" ("groupId");



CREATE INDEX "group_permissions_source_id" ON "public"."group_permissions" USING "btree" ("sourceId");



CREATE INDEX "group_users_user_id" ON "public"."group_users" USING "btree" ("userId");



CREATE INDEX "groups_external_id" ON "public"."groups" USING "btree" ("externalId");



CREATE INDEX "groups_team_id" ON "public"."groups" USING "btree" ("teamId");



CREATE INDEX "import_tasks_import_id" ON "public"."import_tasks" USING "btree" ("importId");



CREATE INDEX "import_tasks_state_import_id" ON "public"."import_tasks" USING "btree" ("state", "importId");



CREATE INDEX "imports_service_team_id" ON "public"."imports" USING "btree" ("service", "teamId");



CREATE INDEX "imports_state_team_id" ON "public"."imports" USING "btree" ("state", "teamId");



CREATE INDEX "integrations_service_type" ON "public"."integrations" USING "btree" ("service", "type");



CREATE INDEX "integrations_service_type_createdAt" ON "public"."integrations" USING "btree" ("service", "type", "createdAt");



CREATE INDEX "integrations_settings_slack_gin" ON "public"."integrations" USING "gin" ((("settings" -> 'slack'::"text"))) WHERE ((("service")::"text" = 'slack'::"text") AND (("type")::"text" = 'linkedAccount'::"text"));



CREATE INDEX "integrations_team_id_type_service" ON "public"."integrations" USING "btree" ("teamId", "type", "service");



CREATE INDEX "notifications_created_at" ON "public"."notifications" USING "btree" ("createdAt");



CREATE INDEX "notifications_document_id_user_id" ON "public"."notifications" USING "btree" ("documentId", "userId");



CREATE INDEX "notifications_emailed_at" ON "public"."notifications" USING "btree" ("emailedAt");



CREATE INDEX "notifications_event" ON "public"."notifications" USING "btree" ("event");



CREATE INDEX "notifications_team_id_user_id" ON "public"."notifications" USING "btree" ("teamId", "userId");



CREATE INDEX "oauth_authentications_grant_id" ON "public"."oauth_authentications" USING "btree" ("grantId");



CREATE INDEX "oauth_authorization_codes_grant_id" ON "public"."oauth_authorization_codes" USING "btree" ("grantId");



CREATE INDEX "oauth_clients_team_id" ON "public"."oauth_clients" USING "btree" ("teamId");



CREATE INDEX "pins_collection_id" ON "public"."pins" USING "btree" ("collectionId");



CREATE INDEX "pins_team_id" ON "public"."pins" USING "btree" ("teamId");



CREATE INDEX "reactions_comment_id" ON "public"."reactions" USING "btree" ("commentId");



CREATE INDEX "reactions_emoji_user_id" ON "public"."reactions" USING "btree" ("emoji", "userId");



CREATE INDEX "relationships_document_id_type" ON "public"."relationships" USING "btree" ("documentId", "type");



CREATE INDEX "revisions_created_at" ON "public"."revisions" USING "btree" ("createdAt");



CREATE INDEX "revisions_document_id" ON "public"."revisions" USING "btree" ("documentId");



CREATE INDEX "search_queries_created_at" ON "public"."search_queries" USING "btree" ("createdAt");



CREATE INDEX "search_queries_team_id" ON "public"."search_queries" USING "btree" ("teamId");



CREATE INDEX "search_queries_user_id" ON "public"."search_queries" USING "btree" ("userId");



CREATE UNIQUE INDEX "shares_urlId_teamId_not_revoked_uk" ON "public"."shares" USING "btree" ("urlId", "teamId") WHERE ("revokedAt" IS NULL);



CREATE INDEX "stars_document_id_user_id" ON "public"."stars" USING "btree" ("documentId", "userId");



CREATE INDEX "stars_user_id_document_id" ON "public"."stars" USING "btree" ("userId", "documentId");



CREATE UNIQUE INDEX "subscriptions_user_id_collection_id_event" ON "public"."subscriptions" USING "btree" ("userId", "collectionId", "event");



CREATE UNIQUE INDEX "subscriptions_user_id_document_id_event" ON "public"."subscriptions" USING "btree" ("userId", "documentId", "event");



CREATE UNIQUE INDEX "team_domains_team_id_name" ON "public"."team_domains" USING "btree" ("teamId", "name");



CREATE INDEX "teams_previous_subdomains" ON "public"."teams" USING "gin" ("previousSubdomains");



CREATE INDEX "teams_subdomain" ON "public"."teams" USING "btree" ("subdomain");



CREATE INDEX "user_authentications_providerId_createdAt" ON "public"."user_authentications" USING "btree" ("providerId", "createdAt");



CREATE INDEX "user_authentications_user_id" ON "public"."user_authentications" USING "btree" ("userId");



CREATE INDEX "user_passkeys_user_id" ON "public"."user_passkeys" USING "btree" ("userId");



CREATE INDEX "user_permissions_collection_id_user_id" ON "public"."user_permissions" USING "btree" ("collectionId", "userId");



CREATE INDEX "user_permissions_document_id_user_id" ON "public"."user_permissions" USING "btree" ("documentId", "userId");



CREATE INDEX "user_permissions_source_id" ON "public"."user_permissions" USING "btree" ("sourceId");



CREATE INDEX "user_permissions_user_id" ON "public"."user_permissions" USING "btree" ("userId");



CREATE INDEX "users_email" ON "public"."users" USING "btree" ("email");



CREATE INDEX "users_team_id" ON "public"."users" USING "btree" ("teamId");



CREATE INDEX "views_document_id_user_id" ON "public"."views" USING "btree" ("documentId", "userId");



CREATE INDEX "views_updated_at" ON "public"."views" USING "btree" ("updatedAt");



CREATE INDEX "views_user_id" ON "public"."views" USING "btree" ("userId");



CREATE INDEX "webhook_deliveries_createdAt" ON "public"."webhook_deliveries" USING "btree" ("createdAt");



CREATE INDEX "webhook_deliveries_webhook_subscription_id" ON "public"."webhook_deliveries" USING "btree" ("webhookSubscriptionId");



CREATE INDEX "webhook_subscriptions_team_id_enabled" ON "public"."webhook_subscriptions" USING "btree" ("teamId", "enabled");



CREATE OR REPLACE TRIGGER "atlases_tsvectorupdate" BEFORE INSERT OR UPDATE ON "public"."collections" FOR EACH ROW EXECUTE FUNCTION "public"."atlases_search_trigger"();



CREATE OR REPLACE TRIGGER "documents_tsvectorupdate" BEFORE INSERT OR UPDATE ON "public"."documents" FOR EACH ROW EXECUTE FUNCTION "public"."documents_search_trigger"();



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."authentication_providers"
    ADD CONSTRAINT "authentication_providers_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."authentications"
    ADD CONSTRAINT "authentications_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."authentications"
    ADD CONSTRAINT "authentications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "backlinks_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "backlinks_reverseDocumentId_fkey" FOREIGN KEY ("reverseDocumentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "backlinks_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_apiImportId_fkey" FOREIGN KEY ("apiImportId") REFERENCES "public"."imports"("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_archivedById_fkey" FOREIGN KEY ("archivedById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_importId_fkey" FOREIGN KEY ("importId") REFERENCES "public"."file_operations"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_parentCommentId_fkey" FOREIGN KEY ("parentCommentId") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_apiImportId_fkey" FOREIGN KEY ("apiImportId") REFERENCES "public"."imports"("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_atlasId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_importId_fkey" FOREIGN KEY ("importId") REFERENCES "public"."file_operations"("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_lastModifiedById_fkey" FOREIGN KEY ("lastModifiedById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_parentDocumentId_fkey" FOREIGN KEY ("parentDocumentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emojis"
    ADD CONSTRAINT "emojis_attachmentId_fkey" FOREIGN KEY ("attachmentId") REFERENCES "public"."attachments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emojis"
    ADD CONSTRAINT "emojis_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emojis"
    ADD CONSTRAINT "emojis_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."file_operations"
    ADD CONSTRAINT "file_operations_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."file_operations"
    ADD CONSTRAINT "file_operations_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."file_operations"
    ADD CONSTRAINT "file_operations_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."file_operations"
    ADD CONSTRAINT "file_operations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."group_permissions"
    ADD CONSTRAINT "group_permissions_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."group_permissions"
    ADD CONSTRAINT "group_permissions_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."group_permissions"
    ADD CONSTRAINT "group_permissions_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_permissions"
    ADD CONSTRAINT "group_permissions_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "public"."groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_permissions"
    ADD CONSTRAINT "group_permissions_sourceId_fkey" FOREIGN KEY ("sourceId") REFERENCES "public"."group_permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_users"
    ADD CONSTRAINT "group_users_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."group_users"
    ADD CONSTRAINT "group_users_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "public"."groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_users"
    ADD CONSTRAINT "group_users_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."import_tasks"
    ADD CONSTRAINT "import_tasks_importId_fkey" FOREIGN KEY ("importId") REFERENCES "public"."imports"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."imports"
    ADD CONSTRAINT "imports_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."imports"
    ADD CONSTRAINT "imports_integrationId_fkey" FOREIGN KEY ("integrationId") REFERENCES "public"."integrations"("id");



ALTER TABLE ONLY "public"."imports"
    ADD CONSTRAINT "imports_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integrations_authenticationId_fkey" FOREIGN KEY ("authenticationId") REFERENCES "public"."authentications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integrations_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integrations_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integrations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "public"."groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_revisionId_fkey" FOREIGN KEY ("revisionId") REFERENCES "public"."revisions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oauth_authentications"
    ADD CONSTRAINT "oauth_authentications_oauthClientId_fkey" FOREIGN KEY ("oauthClientId") REFERENCES "public"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oauth_authentications"
    ADD CONSTRAINT "oauth_authentications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oauth_authorization_codes"
    ADD CONSTRAINT "oauth_authorization_codes_oauthClientId_fkey" FOREIGN KEY ("oauthClientId") REFERENCES "public"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oauth_authorization_codes"
    ADD CONSTRAINT "oauth_authorization_codes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reactions"
    ADD CONSTRAINT "reactions_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reactions"
    ADD CONSTRAINT "reactions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."revisions"
    ADD CONSTRAINT "revisions_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."revisions"
    ADD CONSTRAINT "revisions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."search_queries"
    ADD CONSTRAINT "search_queries_shareId_fkey" FOREIGN KEY ("shareId") REFERENCES "public"."shares"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."search_queries"
    ADD CONSTRAINT "search_queries_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."search_queries"
    ADD CONSTRAINT "search_queries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_revokedById_fkey" FOREIGN KEY ("revokedById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."shares"
    ADD CONSTRAINT "shares_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."stars"
    ADD CONSTRAINT "stars_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stars"
    ADD CONSTRAINT "stars_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stars"
    ADD CONSTRAINT "stars_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_domains"
    ADD CONSTRAINT "team_domains_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."team_domains"
    ADD CONSTRAINT "team_domains_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_authentications"
    ADD CONSTRAINT "user_authentications_authenticationProviderId_fkey" FOREIGN KEY ("authenticationProviderId") REFERENCES "public"."authentication_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_authentications"
    ADD CONSTRAINT "user_authentications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_passkeys"
    ADD CONSTRAINT "user_passkeys_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_permissions"
    ADD CONSTRAINT "user_permissions_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "public"."collections"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_permissions"
    ADD CONSTRAINT "user_permissions_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_permissions"
    ADD CONSTRAINT "user_permissions_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "public"."documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_permissions"
    ADD CONSTRAINT "user_permissions_sourceId_fkey" FOREIGN KEY ("sourceId") REFERENCES "public"."user_permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_permissions"
    ADD CONSTRAINT "user_permissions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_invitedById_fkey" FOREIGN KEY ("invitedById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_suspendedById_fkey" FOREIGN KEY ("suspendedById") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhook_deliveries"
    ADD CONSTRAINT "webhook_deliveries_webhookSubscriptionId_fkey" FOREIGN KEY ("webhookSubscriptionId") REFERENCES "public"."webhook_subscriptions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhook_subscriptions"
    ADD CONSTRAINT "webhook_subscriptions_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhook_subscriptions"
    ADD CONSTRAINT "webhook_subscriptions_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "public"."teams"("id") ON DELETE CASCADE;





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."atlases_search_trigger"() TO "anon";
GRANT ALL ON FUNCTION "public"."atlases_search_trigger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."atlases_search_trigger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."documents_search_trigger"() TO "anon";
GRANT ALL ON FUNCTION "public"."documents_search_trigger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."documents_search_trigger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";


















GRANT ALL ON TABLE "public"."SequelizeMeta" TO "anon";
GRANT ALL ON TABLE "public"."SequelizeMeta" TO "authenticated";
GRANT ALL ON TABLE "public"."SequelizeMeta" TO "service_role";



GRANT ALL ON TABLE "public"."apiKeys" TO "anon";
GRANT ALL ON TABLE "public"."apiKeys" TO "authenticated";
GRANT ALL ON TABLE "public"."apiKeys" TO "service_role";



GRANT ALL ON TABLE "public"."attachments" TO "anon";
GRANT ALL ON TABLE "public"."attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."attachments" TO "service_role";



GRANT ALL ON TABLE "public"."authentication_providers" TO "anon";
GRANT ALL ON TABLE "public"."authentication_providers" TO "authenticated";
GRANT ALL ON TABLE "public"."authentication_providers" TO "service_role";



GRANT ALL ON TABLE "public"."authentications" TO "anon";
GRANT ALL ON TABLE "public"."authentications" TO "authenticated";
GRANT ALL ON TABLE "public"."authentications" TO "service_role";



GRANT ALL ON TABLE "public"."relationships" TO "anon";
GRANT ALL ON TABLE "public"."relationships" TO "authenticated";
GRANT ALL ON TABLE "public"."relationships" TO "service_role";



GRANT ALL ON TABLE "public"."backlinks" TO "anon";
GRANT ALL ON TABLE "public"."backlinks" TO "authenticated";
GRANT ALL ON TABLE "public"."backlinks" TO "service_role";



GRANT ALL ON TABLE "public"."group_permissions" TO "anon";
GRANT ALL ON TABLE "public"."group_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."group_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."collection_groups" TO "anon";
GRANT ALL ON TABLE "public"."collection_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."collection_groups" TO "service_role";



GRANT ALL ON TABLE "public"."user_permissions" TO "anon";
GRANT ALL ON TABLE "public"."user_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."user_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."collection_users" TO "anon";
GRANT ALL ON TABLE "public"."collection_users" TO "authenticated";
GRANT ALL ON TABLE "public"."collection_users" TO "service_role";



GRANT ALL ON TABLE "public"."collections" TO "anon";
GRANT ALL ON TABLE "public"."collections" TO "authenticated";
GRANT ALL ON TABLE "public"."collections" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON TABLE "public"."documents" TO "anon";
GRANT ALL ON TABLE "public"."documents" TO "authenticated";
GRANT ALL ON TABLE "public"."documents" TO "service_role";



GRANT ALL ON TABLE "public"."emojis" TO "anon";
GRANT ALL ON TABLE "public"."emojis" TO "authenticated";
GRANT ALL ON TABLE "public"."emojis" TO "service_role";



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."file_operations" TO "anon";
GRANT ALL ON TABLE "public"."file_operations" TO "authenticated";
GRANT ALL ON TABLE "public"."file_operations" TO "service_role";



GRANT ALL ON TABLE "public"."group_users" TO "anon";
GRANT ALL ON TABLE "public"."group_users" TO "authenticated";
GRANT ALL ON TABLE "public"."group_users" TO "service_role";



GRANT ALL ON TABLE "public"."groups" TO "anon";
GRANT ALL ON TABLE "public"."groups" TO "authenticated";
GRANT ALL ON TABLE "public"."groups" TO "service_role";



GRANT ALL ON TABLE "public"."import_tasks" TO "anon";
GRANT ALL ON TABLE "public"."import_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."import_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."imports" TO "anon";
GRANT ALL ON TABLE "public"."imports" TO "authenticated";
GRANT ALL ON TABLE "public"."imports" TO "service_role";



GRANT ALL ON TABLE "public"."integrations" TO "anon";
GRANT ALL ON TABLE "public"."integrations" TO "authenticated";
GRANT ALL ON TABLE "public"."integrations" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."oauth_authentications" TO "anon";
GRANT ALL ON TABLE "public"."oauth_authentications" TO "authenticated";
GRANT ALL ON TABLE "public"."oauth_authentications" TO "service_role";



GRANT ALL ON TABLE "public"."oauth_authorization_codes" TO "anon";
GRANT ALL ON TABLE "public"."oauth_authorization_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."oauth_authorization_codes" TO "service_role";



GRANT ALL ON TABLE "public"."oauth_clients" TO "anon";
GRANT ALL ON TABLE "public"."oauth_clients" TO "authenticated";
GRANT ALL ON TABLE "public"."oauth_clients" TO "service_role";



GRANT ALL ON TABLE "public"."pins" TO "anon";
GRANT ALL ON TABLE "public"."pins" TO "authenticated";
GRANT ALL ON TABLE "public"."pins" TO "service_role";



GRANT ALL ON TABLE "public"."reactions" TO "anon";
GRANT ALL ON TABLE "public"."reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."reactions" TO "service_role";



GRANT ALL ON TABLE "public"."revisions" TO "anon";
GRANT ALL ON TABLE "public"."revisions" TO "authenticated";
GRANT ALL ON TABLE "public"."revisions" TO "service_role";



GRANT ALL ON TABLE "public"."search_queries" TO "anon";
GRANT ALL ON TABLE "public"."search_queries" TO "authenticated";
GRANT ALL ON TABLE "public"."search_queries" TO "service_role";



GRANT ALL ON TABLE "public"."shares" TO "anon";
GRANT ALL ON TABLE "public"."shares" TO "authenticated";
GRANT ALL ON TABLE "public"."shares" TO "service_role";



GRANT ALL ON TABLE "public"."stars" TO "anon";
GRANT ALL ON TABLE "public"."stars" TO "authenticated";
GRANT ALL ON TABLE "public"."stars" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."team_domains" TO "anon";
GRANT ALL ON TABLE "public"."team_domains" TO "authenticated";
GRANT ALL ON TABLE "public"."team_domains" TO "service_role";



GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";



GRANT ALL ON TABLE "public"."user_authentications" TO "anon";
GRANT ALL ON TABLE "public"."user_authentications" TO "authenticated";
GRANT ALL ON TABLE "public"."user_authentications" TO "service_role";



GRANT ALL ON TABLE "public"."user_passkeys" TO "anon";
GRANT ALL ON TABLE "public"."user_passkeys" TO "authenticated";
GRANT ALL ON TABLE "public"."user_passkeys" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."views" TO "anon";
GRANT ALL ON TABLE "public"."views" TO "authenticated";
GRANT ALL ON TABLE "public"."views" TO "service_role";



GRANT ALL ON TABLE "public"."webhook_deliveries" TO "anon";
GRANT ALL ON TABLE "public"."webhook_deliveries" TO "authenticated";
GRANT ALL ON TABLE "public"."webhook_deliveries" TO "service_role";



GRANT ALL ON TABLE "public"."webhook_subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."webhook_subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."webhook_subscriptions" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































