SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: region_closures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.region_closures (
    ancestor_id uuid NOT NULL,
    descendant_id uuid NOT NULL,
    depth integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regions (
    id uuid DEFAULT uuidv7() NOT NULL,
    public_id text NOT NULL,
    parent_id uuid,
    name text NOT NULL,
    slug text NOT NULL,
    region_type text NOT NULL,
    summary text,
    description text,
    external_ref text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT uuidv7() NOT NULL,
    user_id uuid NOT NULL,
    user_identity_id uuid NOT NULL,
    authentication_method text NOT NULL,
    ip_address inet,
    user_agent text,
    last_seen_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    token_digest text NOT NULL
);


--
-- Name: spots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spots (
    id uuid DEFAULT uuidv7() NOT NULL,
    public_id text NOT NULL,
    region_id uuid NOT NULL,
    spot_type text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    summary text,
    description text,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    location public.geography(Point,4326) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_identities (
    id uuid DEFAULT uuidv7() NOT NULL,
    user_id uuid NOT NULL,
    provider text NOT NULL,
    provider_uid text,
    email public.citext,
    email_verified boolean DEFAULT false NOT NULL,
    password_digest text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    password_reset_token_digest text,
    password_reset_sent_at timestamp with time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT uuidv7() NOT NULL,
    primary_email public.citext NOT NULL,
    primary_email_verified_at timestamp with time zone,
    role text DEFAULT 'member'::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    display_name text,
    locale text DEFAULT 'en'::text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: waterfalls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.waterfalls (
    id uuid DEFAULT uuidv7() NOT NULL,
    spot_id uuid NOT NULL,
    height_meters numeric(6,2),
    plunge_pool boolean,
    flow_seasonality text,
    approach_difficulty text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: region_closures region_closures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_closures
    ADD CONSTRAINT region_closures_pkey PRIMARY KEY (ancestor_id, descendant_id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: spots spots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spots
    ADD CONSTRAINT spots_pkey PRIMARY KEY (id);


--
-- Name: user_identities user_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: waterfalls waterfalls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.waterfalls
    ADD CONSTRAINT waterfalls_pkey PRIMARY KEY (id);


--
-- Name: index_region_closures_on_ancestor_id_and_depth; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_region_closures_on_ancestor_id_and_depth ON public.region_closures USING btree (ancestor_id, depth);


--
-- Name: index_region_closures_on_descendant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_region_closures_on_descendant_id ON public.region_closures USING btree (descendant_id);


--
-- Name: index_regions_on_external_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_external_ref ON public.regions USING btree (external_ref) WHERE (external_ref IS NOT NULL);


--
-- Name: index_regions_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_parent_id ON public.regions USING btree (parent_id);


--
-- Name: index_regions_on_parent_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_parent_id_and_slug ON public.regions USING btree (parent_id, slug) WHERE (parent_id IS NOT NULL);


--
-- Name: index_regions_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_public_id ON public.regions USING btree (public_id);


--
-- Name: index_regions_on_slug_where_parent_id_is_null; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_slug_where_parent_id_is_null ON public.regions USING btree (slug) WHERE (parent_id IS NULL);


--
-- Name: index_regions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_status ON public.regions USING btree (status);


--
-- Name: index_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: index_sessions_on_revoked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_revoked_at ON public.sessions USING btree (revoked_at);


--
-- Name: index_sessions_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_token_digest ON public.sessions USING btree (token_digest);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_sessions_on_user_identity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_identity_id ON public.sessions USING btree (user_identity_id);


--
-- Name: index_spots_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spots_on_location ON public.spots USING gist (location);


--
-- Name: index_spots_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_spots_on_public_id ON public.spots USING btree (public_id);


--
-- Name: index_spots_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spots_on_region_id ON public.spots USING btree (region_id);


--
-- Name: index_spots_on_region_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_spots_on_region_id_and_slug ON public.spots USING btree (region_id, slug);


--
-- Name: index_spots_on_spot_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spots_on_spot_type ON public.spots USING btree (spot_type);


--
-- Name: index_spots_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spots_on_status ON public.spots USING btree (status);


--
-- Name: index_user_identities_on_password_reset_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_password_reset_token_digest ON public.user_identities USING btree (password_reset_token_digest) WHERE (password_reset_token_digest IS NOT NULL);


--
-- Name: index_user_identities_on_provider_and_provider_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_provider_and_provider_uid ON public.user_identities USING btree (provider, provider_uid) WHERE (provider_uid IS NOT NULL);


--
-- Name: index_user_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_identities_on_user_id ON public.user_identities USING btree (user_id);


--
-- Name: index_user_identities_on_user_id_and_provider_for_password; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_user_id_and_provider_for_password ON public.user_identities USING btree (user_id, provider) WHERE (provider = 'password'::text);


--
-- Name: index_users_on_primary_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_primary_email ON public.users USING btree (primary_email);


--
-- Name: index_waterfalls_on_spot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_waterfalls_on_spot_id ON public.waterfalls USING btree (spot_id);


--
-- Name: region_closures region_closures_ancestor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_closures
    ADD CONSTRAINT region_closures_ancestor_id_fkey FOREIGN KEY (ancestor_id) REFERENCES public.regions(id) ON DELETE CASCADE;


--
-- Name: region_closures region_closures_descendant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_closures
    ADD CONSTRAINT region_closures_descendant_id_fkey FOREIGN KEY (descendant_id) REFERENCES public.regions(id) ON DELETE CASCADE;


--
-- Name: regions regions_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.regions(id) ON DELETE SET NULL;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_identity_id_fkey FOREIGN KEY (user_identity_id) REFERENCES public.user_identities(id) ON DELETE CASCADE;


--
-- Name: spots spots_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spots
    ADD CONSTRAINT spots_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.regions(id) ON DELETE RESTRICT;


--
-- Name: user_identities user_identities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: waterfalls waterfalls_spot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.waterfalls
    ADD CONSTRAINT waterfalls_spot_id_fkey FOREIGN KEY (spot_id) REFERENCES public.spots(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260315222004'),
('20260315213827'),
('20260314234833'),
('20260314143000'),
('20260314142000'),
('20260314093000');
