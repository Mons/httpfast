use utf8;
use strict;
use warnings;

package HTTPFast;
our $VERSION = '0.1';

require XSLoader;
XSLoader::load('HTTPFast', $VERSION);


package HTTPFast::Message;

sub abc {

}

package HTTPFast::Response;
use base 'HTTPFast::Message';

package HTTPFast::Request;
use base 'HTTPFast::Message';





1;
