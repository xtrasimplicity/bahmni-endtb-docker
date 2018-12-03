FROM centos:6.9

RUN yum install -y python-setuptools openssh sudo wget unzip && \
    yum install -y https://dl.bintray.com/bahmni/rpm/rpms/bahmni-installer-0.88-123.noarch.rpm

RUN cd /etc/bahmni-installer/deployment-artifacts && \
    wget https://github.com/DWB-eHealth/endtb-config/archive/2.0.3.zip && \
    unzip 2.0.3.zip && \
    mv endtb-config-2.0.3 endtb_config && \
    cp endtb_config/dbdump/mysql_dump.sql openmrs_backup.sql

RUN wget https://raw.githubusercontent.com/DWB-eHealth/endtb-config/2.0.3/playbooks/examples/inventory -O /etc/bahmni-installer/local
ADD artifacts/setup.yml /etc/bahmni-installer
ADD artifacts/jre-7u79-linux-x64.rpm /opt

#Manually patch the Oracle Java playbook due to deprecation of old download links.
RUN wget https://raw.githubusercontent.com/Bahmni/bahmni-playbooks/release-0.89/roles/oracle-java/defaults/main.yml -O /opt/bahmni-installer/bahmni-playbooks/roles/oracle-java/defaults/main.yml

# Ignore Selinux tasks
RUN echo '---' > /opt/bahmni-installer/bahmni-playbooks/roles/selinux/tasks/main.yml

# Mock SSH server config, to keep the installer happy.
RUN mkdir -p /etc/ssh && \
    touch /etc/ssh/sshd_config && \
    echo -e '#!/bin/sh\necho "This is a fake SSH service. It does not do anything."' > /etc/init.d/sshd && \
    chmod +x /etc/init.d/sshd

# Mock `iptables`, to keep the installer happy.
RUN mv /sbin/iptables /sbin/iptables-old && \
  echo -e '#!/bin/sh\necho "This is not the real iptables. If you *really* need to, you can use /sbin/iptables-old."' > /sbin/iptables && \
  chmod +x /sbin/iptables && \
  echo -e '#!/bin/sh\necho "This is a fake iptables service. It does not do anything."' > /etc/init.d/iptables && \
  chmod +x /etc/init.d/iptables

RUN yum clean all && \
    bahmni -i local install


RUN bahmni --implementation_play=/var/www/bahmni_config/playbooks/all.yml -i local install-impl

RUN service mysqld start && \
    sudo su -s /bin/bash bahmni -c "/usr/bin/bahmni-batch"

ADD artifacts/bin/start_bahmni /usr/sbin/
RUN chmod +x /usr/sbin/start_bahmni

EXPOSE 80 443

VOLUME /var/www /var/log /opt/bahmni-reports/log /opt/openmrs/log /var/lib/mysql /home/bahmni /etc/bahmni-installer/deployment-artifacts /opt/bahmni-certs

CMD [ "/usr/sbin/start_bahmni" ]