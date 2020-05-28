# postgrest-basic-auth-example
Example on how to secure your PostgREST API with Nginx Basic Authentication

Brainstorming:
* [ ] part 1: password protect with a single user
* [ ] part 2: have a public and protected API
* [ ] part 3: pass the `$remote_user` from Nginx basic_auth in a header and use a custom `pre-request` function to set the role based on it
* [ ] part 4: also show how RLS works (a bit unrelated, but might be the simplest example)
