.PHONY: clean purge

default: tcg.jar launcher.sh
	cat launcher.sh tcg.jar > tcg.run
	chmod +x tcg.run

tcg.jar: document.class
	jar cmvf META-INF/MANIFEST.MF tcg.jar *.class

document.class:
	javac Document.java

clean:
	rm -f Document.class
	rm -f Chunk.class
	rm -f main.jar

purge:
	rm -f tcg.run

test: purge clean test.md default
	./tcg.run test.md