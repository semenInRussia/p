build-all: compiled/pj.exe compiled/p.exe compiled/pp.exe compiled/pf.exe

clean:
	rm compiled/*

compiled/pj.exe: p/print-job.rkt p/print-windows.rkt
	raco exe -o compiled/pj.exe p/print-job.rkt

compiled/p.exe: p/printer.rkt p/print-windows.rkt
	raco exe -o compiled/p.exe p/printer.rkt

compiled/pp.exe: p/print-special-file.rkt p/print-windows.rkt
	raco exe -o compiled/pp.exe p/print-special-file.rkt

compiled/pf.exe: p/print-file.rkt p/print-windows.rkt
	raco exe -o compiled/pf.exe p/print-file.rkt
