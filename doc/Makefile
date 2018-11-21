POD    = $(wildcard *.pod)
HTML   = $(patsubst %.pod, %.html, $(POD))
TXT    = $(patsubst %.pod, %.txt,  $(POD))

all : $(HTML) $(TXT) clean

%.html : %.pod
	pod2html.bat $< >$@

%.txt : %.pod
	pod2text.bat $< >$@

clean : pod2htmd.tmp
	rm $<
