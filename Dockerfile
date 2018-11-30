FROM centos:6.9

RUN yum install -y python-setuptools openssh sudo wget unzip && \
    yum install -y https://dl.bintray.com/bahmni/rpm/rpms/bahmni-installer-0.85-91.noarch.rpm

RUN cd /etc/bahmni-installer/deployment-artifacts && \
    wget https://github.com/Bahmni/endtb-config/archive/release-0.85.zip && \
    unzip release-0.85.zip && \
    mv endtb-config-release-0.85 endtb_config && \
    cp endtb_config/dbdump/mysql_dump.sql openmrs_backup.sql

RUN wget https://raw.githubusercontent.com/Bahmni/endtb-config/release-0.85/playbooks/examples/inventory -O /etc/bahmni-installer/local
ADD artifacts/setup.yml /etc/bahmni-installer
ADD artifacts/jre-7u79-linux-x64.rpm /opt

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

# Remove the duplicate reports-user, this duplicate user messes up the Bahmni reporting function.
RUN service mysqld start && \
    mysql -u root -ppassword -e "use openmrs; UPDATE users set password = '29171af2d2cc6b48ab011c6387daa8516960edd0a7fa4e8bc6eaf1aab1d3d15443a82213fb0d11b3071ca73d45f719d885b2fdabcfef03b54b3102af450cd771' WHERE username = 'reports-user'; DELETE FROM users WHERE user_id = 21;"

RUN bahmni --implementation_play=/var/www/bahmni_config/playbooks/all.yml -i local install-impl

RUN ln -s /etc/bahmni-installer/bahmni.conf /etc/bahmni-installer/bahmni-emr-installer.conf

RUN service mysqld start && \
    sudo su -s /bin/bash bahmni -c "/usr/bin/bahmni-batch"

ADD artifacts/bin/start_bahmni /usr/sbin/
RUN chmod +x /usr/sbin/start_bahmni

EXPOSE 80 443

VOLUME /var/www /var/log /opt/bahmni-reports/log /opt/openmrs/log /var/lib/mysql /home/bahmni /etc/bahmni-installer/deployment-artifacts /opt/bahmni-certs

CMD [ "/usr/sbin/start_bahmni" ]