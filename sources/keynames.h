//
// FILE: keynames.h -- This defines verbal descriptions of various extended keys.  This
//                     is highly dependent on ~wx/include/base/common.h
//
// $Id$
//

#define NUM_KEYS	74		// total # of keys defined here
#define BLANK_STR "      " 	// just a blank string of 7 spaces--maps to 0 key
int key_values[NUM_KEYS]=
{
0		,
8   ,
9   ,
13  ,
27  ,
32  ,
127 ,
300	,
301	,
302	,
303	,
304	,
305	,
306	,
307	,
308	,
309	,
310	,
311	,
312	,
313	,
314	,
315	,
316	,
317	,
318	,
319	,
320	,
321	,
322	,
323	,
324	,
325	,
326	,
327	,
328	,
329	,
330	,
331	,
332	,
333	,
334	,
335	,
336	,
337	,
338	,
339	,
340	,
341	,
342	,
343	,
344	,
345	,
346	,
347	,
348	,
349	,
350	,
351	,
352	,
353	,
354	,
355	,
356	,
357	,
358	,
359	,
360	,
361	,
362	,
363	,
364	,
365	,
366
};

char *key_names[NUM_KEYS]=
{
BLANK_STR,
"BACK",
"TAB",
"RETURN",
"ESCAPE",
"SPACE",
"DELETE",
"START", /*=300*/
"LBUTTON",
"RBUTTON",
"CANCEL",
"MBUTTON",
"CLEAR",
"SHIFT",
"CONTROL",
"MENU",
"PAUSE",
"CAPITAL",
"PRIOR",
"NEXT",
"END",
"HOME",
"LEFT",
"UP",
"RIGHT",
"DOWN",
"SELECT",
"PRINT",
"EXECUTE",
"SNAPSHOT",
"INSERT",
"HELP",
"NUMPAD0",
"NUMPAD1",
"NUMPAD2",
"NUMPAD3",
"NUMPAD4",
"NUMPAD5",
"NUMPAD6",
"NUMPAD7",
"NUMPAD8",
"NUMPAD9",
"MULTIPLY",
"ADD",
"SEPARATOR",
"SUBTRACT",
"DECIMAL",
"DIVIDE",
"F1",
"F2",
"F3",
"F4",
"F5",
"F6",
"F7",
"F8",
"F9",
"F10",
"F11",
"F12",
"F13",
"F14",
"F15",
"F16",
"F17",
"F18",
"F19",
"F20",
"F21",
"F22",
"F23",
"F24",
"NUMLOCK",
"SCROLL"
};

inline int Name2Key(const char *name)
{
for (int i=0;i<NUM_KEYS;i++) if (strcmp(name,key_names[i])==0) return key_values[i];
return 0;
}

inline char *Key2Name(int key)
{
for (int i=0;i<NUM_KEYS;i++) if (key_values[i]==key) return key_names[i];
return 0;
}
