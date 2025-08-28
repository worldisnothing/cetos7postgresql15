# Dockerfile: CentOS 7 + PostgreSQL 15 (без systemd, initdb напрямую)
FROM centos:7

# 1) Переключаемся на vault (архивные зеркала для EL7) и добавляем exclude для postgres
RUN sed -i.bak \
      -e 's|^mirrorlist=|#mirrorlist=|g' \
      -e 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' \
      /etc/yum.repos.d/CentOS-*.repo && \
    sed -i '/^\[base\]/a exclude=postgresql*' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i '/^\[updates\]/a exclude=postgresql*' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i '/^\[extras\]/a exclude=postgresql*' /etc/yum.repos.d/CentOS-Base.repo

# 2) Базовые утилиты + EPEL и CA
RUN yum -y install yum-utils curl ca-certificates wget epel-release && \
    update-ca-trust force-enable && yum clean all

# 3) libzstd для зависимостей PostgreSQL
RUN yum -y install zstd && yum clean all

# 4) Забираем и ставим PGDG repo (правильный URL для EL7)
RUN curl -fSL -o /tmp/pgdg.rpm \
      http://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    rpm -Uvh /tmp/pgdg.rpm && rm -f /tmp/pgdg.rpm

# 5) Устанавливаем PostgreSQL 15 (server + contrib)
RUN yum -y install postgresql15-server postgresql15-contrib && yum clean all

# 6) Переменные и директории
ENV PGDATA=/var/lib/pgsql/15/data
RUN mkdir -p ${PGDATA} && chown -R postgres:postgres /var/lib/pgsql

# 7) Инициализация кластера без systemd — вызываем initdb напрямую от postgres
RUN runuser -u postgres -- /usr/pgsql-15/bin/initdb -D "${PGDATA}"

VOLUME ["${PGDATA}"]
EXPOSE 5432

# 8) Запуск postgres в foreground (PID 1)
CMD ["/usr/pgsql-15/bin/postgres", "-D", "/var/lib/pgsql/15/data", "-c", "listen_addresses=*"]

