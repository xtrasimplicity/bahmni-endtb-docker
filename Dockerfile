FROM centos:6.9

RUN yum install -y python-setuptools openssh sudo wget unzip gettext && \
    yum install -y https://dl.bintray.com/bahmni/rpm/rpms/bahmni-installer-0.85-91.noarch.rpm && \
    cd /etc/bahmni-installer/deployment-artifacts && \
    wget https://github.com/Bahmni/endtb-config/archive/release-0.85.zip && \
    unzip release-0.85.zip && \
    mv endtb-config-release-0.85 endtb_config && \
    cp endtb_config/dbdump/mysql_dump.sql openmrs_backup.sql && \
    wget https://raw.githubusercontent.com/Bahmni/endtb-config/release-0.85/playbooks/examples/inventory -O /etc/bahmni-installer/local && \
    yum clean all

ADD artifacts/setup.yml /etc/bahmni-installer
ADD artifacts/jre-7u79-linux-x64.rpm /opt

ADD artifacts/bin/install_bahmni /tmp_install/

RUN /bin/bash /tmp_install/install_bahmni && \
    rm -rf /tmp_install

ADD artifacts/bin/start_bahmni /usr/sbin/
ADD artifacts/bin/update-config /usr/sbin/
ADD artifacts/bin/bahmnidev /usr/sbin/bahmnidev

RUN chmod u+x /usr/sbin/start_bahmni && \
    chown root /usr/sbin/update-config && \
    chmod 700 /usr/sbin/update-config && \
    chown root /usr/sbin/bahmnidev && \
    chmod 700 /usr/sbin/bahmnidev && \
    ln -s /var/www/bahmni_config /var/www/implementation_config

EXPOSE 80 443

VOLUME /var/www /var/log /opt/bahmni-reports/log /opt/openmrs/log /var/lib/mysql /var/lib/bahmni /home/bahmni /etc/bahmni-installer/deployment-artifacts /opt/bahmni-certs

CMD [ "/usr/sbin/start_bahmni" ]