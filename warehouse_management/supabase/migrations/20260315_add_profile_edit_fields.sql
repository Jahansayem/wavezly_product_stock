alter table public.profiles
  add column if not exists address text,
  add column if not exists email text,
  add column if not exists birthday date,
  add column if not exists gender text,
  add column if not exists avatar_url text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_gender_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_gender_check
      check (gender is null or gender in ('male', 'female', 'other'));
  end if;
end $$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-images',
  'profile-images',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Public can read profile images'
  ) then
    create policy "Public can read profile images"
      on storage.objects for select
      to public
      using (bucket_id = 'profile-images');
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users can upload profile images'
  ) then
    create policy "Users can upload profile images"
      on storage.objects for insert
      to authenticated
      with check (
        bucket_id = 'profile-images'
        and (auth.uid())::text = (storage.foldername(name))[1]
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users can update their profile images'
  ) then
    create policy "Users can update their profile images"
      on storage.objects for update
      to authenticated
      using (
        bucket_id = 'profile-images'
        and (auth.uid())::text = (storage.foldername(name))[1]
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users can delete their profile images'
  ) then
    create policy "Users can delete their profile images"
      on storage.objects for delete
      to authenticated
      using (
        bucket_id = 'profile-images'
        and (auth.uid())::text = (storage.foldername(name))[1]
      );
  end if;
end $$;
