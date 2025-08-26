.. _cli:

CLI
===

PostgREST provides a CLI with the commands listed below:

Help
----

.. code:: bash

  $ postgrest [-h|--help]

Shows all the commands available.

Version
-------

.. code:: bash

  $ postgrest [-v|--version]

Prints the PostgREST version.

Example
-------

.. code:: bash

  $ postgrest [-e|--example]

Shows example configuration options.

Dump Config
-----------

.. code:: bash

  $ postgrest [--dump-config]

Dumps the loaded :ref:`configuration` values, considering the configuration file, environment variables and :ref:`in_db_config`.

Dump Schema
-----------

.. code:: bash

  $ postgrest [--dump-schema]

Dumps the schema cache in JSON format.

Ready Flag
----------

.. code:: bash

  $ postgrest [--ready]

This is analogous to the ``/ready`` endpoint in :ref:`admin_server`. However, instead of an HTTP response, this exits with return code of ``0`` on success and ``1`` on failure.
