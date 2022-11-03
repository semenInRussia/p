build:
	raco exe -o compiled/pj.exe p/print-job.rkt
	raco exe -o compiled/p.exe p/printer.rkt
	raco exe -o compiled/pp.exe p/print-special-file.rkt
	raco exe -o compiled/pf.exe p/print-file.rkt
