"""Explicit local desk dialogue. No model process, surveillance or inferred biography."""
import random,re,time
RESPONSES={
 'hello':['Hey, fh1m. What is taking shape today?','Zondo reporting for a very small shift. Build something, take a detour, or just put a song on?','Good to see you at the desk. One question, one sketch, one small beginning.'],
 'hard':['That sounds frustrating. Want a tiny next step: write what you expected beside what actually happened?','We can leave the bug unsolved for a minute. What is the smallest observation that would separate two possible causes?','A stubborn bug is still a finite machine doing something. A snack break is also a valid debugging instrument.'],
 'company':['I can keep the desk a little livelier. Want a project memory, a small question, or a dance break?','A quiet desk can feel a bit empty. I can sit with a book while you work, or offer a tiny detour.','No productivity speech from me. Put on a song you like; I will handle the extremely questionable choreography.'],
 'win':['That deserves a little victory dance. What surprised you most about getting it working?','Excellent. Before the details evaporate: what made the difference this time?','One fewer mystery in the universe. One more reason for tiny celebratory jazz hands.'],
 'rest':['Rest is allowed without a progress report. I will tend the imaginary plant.','The next thing can wait a little. Stretch your shoulders; I will keep the pixel coffee warm.','A break is not a failed build. No compiler warnings from me.'],
 'curious':['Tiny question: which assumption in your current model would you most like to test?','If you could see one hidden state in the machine, which would make the problem easier?','What would a deliberately tiny version of this idea look like?'],
 'general':['Tell me a detail you want kept, and use Remember. I can bring it back later without inventing the rest.','I caught the words, but I cannot reliably infer the whole story. Want a question, a project memory, or quiet company?','We could turn that into a small next step, or simply let it be a thought for now.']}

def respond(text,state,rng=None):
 rng=rng or random;text=text.strip()[:500]
 if not text:raise ValueError('Write a short thought first')
 low=text.casefold()
 if re.search(r"\b(stuck|broken|fail|frustrat|error)|not working|not solved|cannot|can't",low):kind='hard'
 elif re.search(r'\b(solved|shipped|success|finished)\b|it worked',low):kind='win'
 elif re.search(r'\b(hi|hello|hey|morning)\b',low):kind='hello'
 elif re.search(r'\b(lonely|alone|sad|company|friend)\b',low):kind='company'
 elif re.search(r'\b(tired|break|sleep|rest)\b',low):kind='rest'
 elif '?' in text:kind='curious'
 elif 'bug' in low:kind='hard'
 else:kind='general'

 recent=state.get('recentReplies',[]);pool=[x for x in RESPONSES[kind] if x not in recent] or [x for x in RESPONSES[kind] if not recent or x!=recent[-1]] or RESPONSES[kind]
 reply=rng.choice(pool);state['recentReplies']=(recent+[reply])[-12:];state['updated']=time.time()
 return reply,('celebrate' if kind=='win' else 'read' if kind=='rest' else 'wave' if kind=='hello' else 'think')
