-- 20261025120000_delete_my_account.sql
-- Lets a signed-in user delete their own account from inside the app (Google
-- Play requires in-app account deletion for apps that create accounts).
--
-- The client cannot delete from auth.users itself, and shipping the service
-- role key to the app is not an option, so this runs as SECURITY DEFINER (the
-- migration owner, postgres) and only ever touches the row of the caller:
-- auth.uid() comes from the request's JWT, so there is no parameter to spoof.
-- public.user_favorites cascades on the auth.users delete, as do Supabase's own
-- auth.identities / auth.sessions rows.

create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

-- Functions are executable by PUBLIC by default; only signed-in users may call
-- this one.
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
