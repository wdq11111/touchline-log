-- Touchline starter posts for Card talk. Run once in Supabase → SQL Editor, after forum.sql.
-- Posts as the site owner (the first account that signed in on the website), with the nickname "Touchline".
do $$
declare me uuid;
begin
  select id into me from auth.users order by created_at limit 1;
  if me is null then raise exception 'Sign in on the website once first, then run this again.'; end if;

  insert into public.profiles (id, nickname) values (me, 'Touchline')
  on conflict (id) do update set nickname = excluded.nickname;

  alter table public.forum_threads disable trigger forum_threads_rate;

  insert into public.forum_threads (user_id, card_name, card_pos, card_version, title, body, created_at) values
  (me, 'Any card', null, null,
   'Welcome to Card talk: start here',
   E'This is the place to talk about FC Mobile cards: who is worth your coins and training XP, who looks great on paper but feels slow, and which hidden gems carry your squad.\n\nA few ground rules:\n- One post per card or question, so discussions stay in one place.\n- Say which mode you play (VS Attack, H2H, Manager Mode). A card can be great in one and average in another.\n- Be kind. Use the report button for spam or abuse.\n\nTip: log your matches in the Matches tab and your Player stats will show who actually performs for you. Real numbers beat vibes.',
   now()),
  (me, 'Mbappé', 'ST', null,
   'Mbappé: still the striker everyone should max?',
   E'Most squads I play against have some version of Mbappé up front. Is he still the best use of resources at ST, or are there strikers that feel just as good for less?\n\nIf you have used him, share your version, the mode you play and how he actually performs for you (goals per match from your Player stats is perfect).',
   now() - interval '20 minutes'),
  (me, 'Budget CDM', 'CDM', null,
   'Best budget CDM right now?',
   E'Not everyone can afford the top midfielders. Which CDM gives you the most for the price?\n\nTell us the card, roughly what you paid and what makes him good: interceptions, positioning, passing out of the back. Bonus points if you compare two cards you have both used.',
   now() - interval '40 minutes'),
  (me, 'TOTY picks', null, 'TOTY',
   'TOTY season: which cards are worth your resources?',
   E'Event cards come with a big price tag. Which ones made a real difference in your matches, and which ones did you regret?\n\nPlease include the mode you play and how many matches you have used the card in, so others can judge how reliable your take is.',
   now() - interval '60 minutes'),
  (me, 'Goalkeepers', 'GK', null,
   'Which goalkeeper do you trust in H2H?',
   E'Keepers are hard to judge from stats alone. Some cards feel like a wall, others let in shots that look easy.\n\nWhich GK do you use in H2H, and what convinced you? Did switching keepers change your goals conceded per match in your stats?',
   now() - interval '80 minutes'),
  (me, 'Underrated cards', null, null,
   'Your most underrated card: who outperforms his rating?',
   E'Every squad has that one player who keeps showing up in the MVP list even though nobody talks about him. Who is yours?\n\nPost the card, his position and why he works so well for you.',
   now() - interval '100 minutes');

  alter table public.forum_threads enable trigger forum_threads_rate;
end $$;
