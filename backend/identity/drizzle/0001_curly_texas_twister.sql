CREATE TYPE "public"."profile_type" AS ENUM('buyer', 'seller', 'service_provider');--> statement-breakpoint
CREATE TABLE "profiles" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"type" "profile_type" NOT NULL,
	"display_name" varchar(120),
	"is_default" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" integer,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_by" integer
);
--> statement-breakpoint
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "profiles_user_type_unique" ON "profiles" USING btree ("user_id","type");--> statement-breakpoint
CREATE UNIQUE INDEX "profiles_user_default_unique" ON "profiles" USING btree ("user_id") WHERE "profiles"."is_default";

--> statement-breakpoint
-- Backfill: todo usuario existente recibe un perfil `buyer` por defecto, para
-- que el access token siempre pueda incluir un perfil activo tras este cambio.
INSERT INTO "profiles" ("user_id", "type", "is_default", "created_by", "updated_by")
SELECT u."id", 'buyer', true, u."id", u."id"
FROM "users" u
WHERE NOT EXISTS (
	SELECT 1 FROM "profiles" p WHERE p."user_id" = u."id"
);
