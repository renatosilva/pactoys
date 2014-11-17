all:
	$(MAKE) -C inih
	gcc -Iinih -o repman.exe repman.c inih/libinih.a

clean:
	$(MAKE) -C inih clean
	rm -f repman.exe
