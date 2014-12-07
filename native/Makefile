all:
	$(MAKE) -C inih
	gcc -Iinih -o repman repman.c inih/libinih.a

clean:
	$(MAKE) -C inih clean
	rm -vf repman.exe
	rm -vf repman
