up:
	COMPOSE_PROJECT_NAME=$(DOMAIN) docker-compose up -d --build

purge:
	COMPOSE_PROJECT_NAME=$(DOMAIN) docker-compose down -v

restart:
	COMPOSE_PROJECT_NAME=$(DOMAIN) docker-compose restart

sh-nginx:
	docker exec -ti $(DOMAIN)_nginx sh

sh-php:
	docker exec -ti $(DOMAIN)_php sh

sh-mysql:
	docker exec -ti $(DOMAIN)_mysql sh

backup: backup-code backup-mysql

backup-code:
	mkdir -p backups
	docker exec -ti $(DOMAIN)_php tar -zcvf /tmp/code.tar.gz /code
	docker cp $(DOMAIN)_php:/tmp/code.tar.gz backups/
	docker exec -ti $(DOMAIN)_php rm -rf /tmp/code.tar.gz

backup-mysql:
	mkdir -p backups
	docker exec -ti $(DOMAIN)_mysql sh -c 'mysqldump -u$${MYSQL_USER} -p$${MYSQL_PASSWORD} --databases $${MYSQL_DATABASE} --add-drop-database | gzip -c > /tmp/dump.sql.gz'
	docker cp $(DOMAIN)_mysql:/tmp/dump.sql.gz backups/
	docker exec -ti $(DOMAIN)_mysql rm -rf /tmp/dump.sql.gz

recover: recover-code recover-mysql

recover-code:
	docker cp backups/code.tar.gz $(DOMAIN)_php:/tmp
	docker exec -ti $(DOMAIN)_php sh -c 'rm -rf /code/* && tar -zxvf /tmp/code.tar.gz --strip-components=1 -C /code && rm /tmp/code.tar.gz'

recover-mysql:
	docker cp backups/dump.sql.gz $(DOMAIN)_mysql:/tmp
	docker exec -ti $(DOMAIN)_mysql sh -c 'zcat /tmp/dump.sql.gz | mysql -u$${MYSQL_USER} -p$${MYSQL_PASSWORD} && rm /tmp/dump.sql.gz'
