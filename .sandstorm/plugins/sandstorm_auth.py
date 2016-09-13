import urllib2

from trac.core import *
from trac.perm import PermissionSystem
from trac.web.api import IAuthenticator
from trac.web.session import DetachedSession


class SandstormAuthenticator(Component):

    implements(IAuthenticator)

    def authenticate(self, req):
        user_id = req.get_header('Remote-User')
        if user_id:
            self.log.info("Remote user detected: {}".format(user_id))
            session = DetachedSession(self.env, user_id)
            session['name'] = urllib2.unquote(req.get_header('X-Sandstorm-Username'))
            session.save()

            sandstorm_perms = req.get_header('x-sandstorm-permissions').split(",")
            perms = PermissionSystem(self.env)
            if "admin" in sandstorm_perms and (user_id, 'TRAC_ADMIN') not in perms.get_all_permissions():
                self.log.info("Granting admin permission")
                perms.grant_permission(user_id, 'TRAC_ADMIN')
            return req.get_header('Remote-User')
        return None
