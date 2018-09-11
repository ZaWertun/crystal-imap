URL=http://central.maven.org/maven2/com/icegreen/greenmail-standalone/1.5.8/greenmail-standalone-1.5.8.jar
JAR=greenmail.jar
PARAMS=-Dgreenmail.verbose -Dgreenmail.setup.test.imaps -Dgreenmail.users=test:test@test.org

.PHONY: clean

clean:
	rm -f test/*

test_server: test/greenmail.jar
	java ${PARAMS} -jar test/${JAR}

test/greenmail.jar:
	wget -O test/${JAR} ${URL}
