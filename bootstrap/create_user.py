#!/bin/env python
#
# Create new user accounts in a Galaxy instance
import sys
import getpass
import optparse
import nebulizer

"""
create_user.py

"""

__version__ = '0.0.3'

def get_passwd():
    """Prompt user for a password

    Prompts user to enter and confirm a password. Raises an exception
    if the password is deemed to be invalid (e.g. too short), or if
    the password confirmation fails.

    Returns:
      Password string entered by the user.

    """
    passwd = getpass.getpass("Enter password for new user: ")
    if not nebulizer.validate_password(passwd):
        raise Exception("Invalid password: must be 6 or more characters")
    passwd2 = getpass.getpass("Confirm password: ")
    if passwd2 != passwd:
        raise Exception("Passwords don't match")
    return passwd

def create_user(ni,email,name=None,passwd=None,only_check=False):
    """
    Create a new Galaxy user

    Attempts to create a single user in a Galaxy instance with the
    supplied credentials.

    Arguments:
      ni    : Nebulizer instance associated with a Galaxy instance
      email : email address for the new user
      name  : (optional) name to associate with the user. If
        'None' then will be generated from the email address.
      passwd: (optional) password for the new user. If 'None' then
        the user will be prompted to supply a password.
      only_check: if True then only run the checks, don't try to
        make the user on the system.

    Returns:
      0 on success, 1 on failure.

    """
    # Check if user already exists
    if not ni.check_new_user_info(email,name):
        return 1
    if only_check:
        print "Email and username ok: not currently in use"
        return 0
    # Prompt for password
    if passwd is None:
        try:
            passwd = get_passwd()
        except Exception, ex:
            sys.stderr.write("%s\n" % ex)
            return 1
    # Create the new user
    if not ni.create_user(email,name,passwd):
        return 1
    print "Created new account for %s" % email
    return 0

def create_users_from_template(ni,template,start,end,passwd=None,
                               only_check=False):
    """
    Create a batch of users in Galaxy, based on template email

    Attempts to create multiple users in a Galaxy instance, using
    a template email address and a range of integer indices to
    generate the names.

    'template' should include a '#' symbol indicating where an integer
    index should be substituted (e.g. 'student#@galaxy.ac.uk').
    'start' and 'end' are the range of ids to create (e.g. 1 to 10).

    All accounts will be created with the same password; names will
    be generated automatically from the email addresses

    For example: the template 'student#@galaxy.ac.uk' with a range of
    1 to 5 will generate:

    student1@galaxy.ac.uk
    student2@galaxy.ac.uk
    ...
    student5@galaxy.ac.uk

    Arguments:
      ni       : Nebulizer instance associated with a Galaxy instance
      template : template email address for the batch of new users
      start    : initial integer index for user names
      end      : final integer index for user names
      passwd   : (optional) password for the new user. If 'None' then
        the user will be prompted to supply a password.
      only_check: if True then only run the checks, don't try to
        make the users on the system.

    Returns:
      0 on success, 1 on failure.
    
    """
    # Check template
    name,domain = template.split('@')
    if name.count('#') != 1 or domain.count('#') != 0:
        sys.stderr.write("Incorrect email template format\n")
        return 1
    # Deal with password
    if passwd is not None:
        if not nebulizer.validate_password(passwd):
            sys.stderr.write("Invalid password\n")
            return 1
    else:
        try:
            passwd = get_passwd()
        except Exception, ex:
            sys.stderr.write("%s\n" % ex)
            return 1
    # Generate emails
    emails = [template.replace('#',str(i)) for i in range(start,end+1)]
    # Check that these are available
    print "Checking availability"
    for email in emails:
        name = nebulizer.get_username_from_login(email)
        ##print "%s, %s" % (email,name)
        if not ni.check_new_user_info(email,name):
            return 1
    if only_check:
        print "All emails and usernames ok: not currently in use"
        return 0
    # Make the accounts
    for email in emails:
        name = nebulizer.get_username_from_login(email)
        print "Email : %s" % email
        print "Name  : %s" % name
        if not ni.create_user(email,name,passwd):
            return 1
        print "Created new account for %s" % email
    return 0

def create_batch_of_users(ni,tsv,only_check=False):
    """
    Create a batch of users in Galaxy from a list in a TSV file

    Attempts to create multiple users in a Galaxy instance, using
    a list of email addresses, passwords and (optionally) names
    supplied via a TSV file.

    The file should consist of lines of the form e.g.:

    a.user@galaxy.ac.uk	p@ssw0rd	a-user

    The last value (the public name) can be missing, in which case
    the name will be generated from the email address.

    If an email address is already used for an account in the
    target Galaxy instance then it will be skipped.

    Blank lines and lines starting with '#' are ignored.

    Arguments:
      ni : Nebulizer instance associated with a Galaxy instance
      tsv: Name of TSV file to read user data from
      only_check: if True then only run the checks, don't try to
        make the users on the system.

    Returns:
      0 on success, 1 on failure.
    
    """
    # Open file
    print "Reading data from file '%s'" % tsv
    users = {}
    for line in open(tsv,'r'):
        # Skip blank or comment lines
        if line.startswith('#') or not line.strip():
            continue
        # Extract data
        items = line.strip().split('\t')
        passwd = None
        name = None
        try:
            email = items[0].lower().strip()
            passwd = items[1].strip()
            name = items[2].strip()
        except IndexError:
            pass
        # Do checks
        if email in users:
            sys.stderr.write("%s: appears multiple times\n" % email)
            return 1
        if passwd is None:
            sys.stderr.write("%s: no password supplied\n" % email)
            return 1
        elif not nebulizer.validate_password(passwd):
            sys.stderr.write("%s: invalid password\n" % email)
            return 1
        if name is None:
            name = nebulizer.get_username_from_login(email)
        if ni.check_new_user_info(email,name):
            users[email] = { 'name': name, 'passwd': passwd }
            print "%s\t%s\t%s" % (email,'*****',name)
    if only_check:
        return 0
    # Make the accounts
    for email in users:
        name = users[email]['name']
        passwd = users[email]['passwd']
        if not ni.create_user(email,name,passwd):
            return 1
        print "Created new account for %s" % email
    return 0

if __name__ == "__main__":
    # Collect arguments
    p = optparse.OptionParser(usage=\
                              "\n\t%prog [options] GALAXY_URL API_KEY EMAIL [PUBLIC_NAME]"
                              "\n\t%prog -t [options] GALAXY_URL API_KEY TEMPLATE START [END]"
                              "\n\t%prog -b GALAXY_URL API_KEY FILE",
                              version="%%prog %s" % __version__,
                              description="Create new user(s) in the specified Galaxy "
                              "instance.")
    p.add_option('-p','--password',action='store',dest='passwd',default=None,
                 help="specify password for new user account (otherwise program will "
                 "prompt for password)")
    p.add_option('-c','--check',action='store_true',dest='check',default=False,
                 help="check user details but don't try to create the new account")
    p.add_option('-t','--template',action='store_true',dest='template',default=False,
                 help="indicates that EMAIL is actually a 'template' email address which "
                 "includes a '#' symbol as a placeholder where an integer index should be "
                 "substituted to make multiple accounts (e.g. 'student#@galaxy.ac.uk'). "
                 "The --range option supplies the range of integer indices.")
    p.add_option('-b','--batch',action='store_true',dest='batch',default=False,
                 help="create multiple users reading details from TSV file (columns "
                 "should be: email,password[,public_name])")
    options,args = p.parse_args()
    if len(args) < 3:
        p.error("Wrong arguments")
    galaxy_url = args[0]
    api_key = args[1]
    passwd = options.passwd

    # Set up Nebulizer instance to interact with Galaxy
    ni = nebulizer.Nebulizer(galaxy_url,api_key)

    # Determine mode of operation
    print "Create new users in Galaxy instance at %s" % galaxy_url
    if options.template:
        # Get the template and range of indices
        template = args[2]
        start = int(args[3])
        try:
            end = int(args[4])
        except IndexError:
            end = start
        # Create users
        retval = create_users_from_template(ni,template,start,end,passwd,
                                            only_check=options.check)
    elif options.batch:
        # Get the file with the user data
        tsvfile = args[2]
        # Create users
        retval = create_batch_of_users(ni,tsvfile,only_check=options.check)
    else:
        # Collect email and (optionally) public name
        email = args[2]
        try:
            name = args[3]
            if not nebulizer.check_username_format(name):
                sys.stderr.write("Invalid name: must contain only lower-case letters, "
                                 "numbers and '-'\n")
                sys.exit(1)
        except IndexError:
            # No public name supplied, make from email address
            name = nebulizer.get_username_from_login(email)
        # Create user
        print "Email : %s" % email
        print "Name  : %s" % name
        retval = create_user(ni,email,name,passwd,
                             only_check=options.check)

    # Finished
    sys.exit(retval)
    
