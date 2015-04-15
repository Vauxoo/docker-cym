FROM vauxoo/odoo-70-image
RUN echo Etc/Utc > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
ENV TZ Etc/UTC
RUN pip install python-Levenshtein
RUN adduser --home=/home/production --disabled-password --gecos "" --shell=/bin/bash production
RUN echo 'root:production' |chpasswd
ADD files/instance /home/production/instance
ENV ODOO_USER production
ENV HOME /home/production
ENV ODOO_CONFIG_FILE /home/production/instance/config/instance.conf
ENV ODOO_FILESTORE_PATH /home/production/filestore 
ADD files/supervisord.conf  /etc/supervisor/conf.d/supervisord.conf
RUN wget -O /entry_point.py https://raw.githubusercontent.com/Vauxoo/docker_entrypoint/master/entry_point.py \
    && chmod +x /entry_point.py
RUN mkdir /home/production/.ssh
ADD files/id_rsa /home/production/.ssh/id_rsa

RUN chown -R production:production /home/production
USER production
RUN chmod 600 /home/production/.ssh/id_rsa
RUN ssh-keyscan github.com > /home/production/.ssh/known_hosts \
    && ssh-keyscan launchpad.net >> /home/production/.ssh/known_hosts \
    && ssh-keyscan bitbucket.org >> /home/production/.ssh/known_hosts
RUN mkdir -p /home/production/instance/config
ADD files/instance.conf /home/production/instance/config/instance.conf
RUN cd /home/production/instance && git clone -b 7.0 --single-branch --depth=1 git@github.com:odoo/odoo.git
RUN cd /home/production/instance/extra_addons && git clone -b 7.0 --single-branch --depth=1 git@github.com:Vauxoo/addons-vauxoo.git
RUN cd /home/production/instance/extra_addons && git clone -b 7.0 --single-branch --depth=1 git@github.com:Vauxoo/odoo-mexico-v2.git
RUN mkdir /home/production/filestore \
    && ln -s /home/production/filestore /home/production/instance/odoo/openerp/filestore
RUN rm /home/production/.ssh/id_rsa
USER root
VOLUME ["/home/production/filestore", "/home/production/.ssh", "/var/log/supervisor", "/tmp"]
EXPOSE 8069
EXPOSE 8072
CMD /entry_point.py

