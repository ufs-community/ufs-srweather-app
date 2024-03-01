.. _doc-guidelines:

Documentation
=============

.. note:: 
   
   Thank you to the Unified Workflow (UW) team for allowing us to adapt their documentation guidance for use in the SRW App. The original can be viewed in the `uwtools` :uw:`documentation <sections/contributor_guide/documentation.html>`.


Locally Building and Previewing Documentation
---------------------------------------------

To locally build the docs:

#. Install ``sphinx``, ``sphinx-rtd-theme``, and ``sphinxcontrib-bibtex`` on your system if they are not already installed. 
#. From the root of your clone: ``cd doc``
#. Build the docs: ``make doc``

The ``make doc`` command will build the documentation under ``doc/build/html``, after which you can preview them in your web browser at the URL:

.. code-block:: text

   file://<filesystem-path-to-your-clone>/doc/build/html/index.html

Rerun ``make doc`` and refresh your browser after making and saving changes.

Viewing Online Documentation
----------------------------

Online documentation generation and hosting for the SRW App is provided by :rtd:`Read the Docs<>`. The green *View Docs* button near the upper right of that page links to the official docs for the project. When viewing the documentation, the version selector at the bottom of the navigation column on the left can be used to switch between the latest development code (``develop``), the latest released version (``latest``), and any previously released version.

Docs are also built and temporarily published when Pull Requests (PRs) targeting the ``develop`` branch are opened. Visit the :rtd:`Builds page<builds>` to see recent builds, including those made for PRs. Click a PR-related build marked *Passed*, then the small *View docs* link (**not** the large green *View Docs* button) to see the docs built specifically for that PR. If your PR includes documentation updates, it may be helpful to include the URL of this build in your PR's description so that reviewers can see the rendered HTML docs and not just the modified ``.rst`` files. Note that if commits are pushed to the PR's source branch, Read the Docs will rebuild the PR docs. See the checks section near the bottom of a PR for current status and for another link to the PR docs via the *Details* link.

.. COMMENT: Technically, docs are built when any PR is opened, regardless of branch. Look into changing. 

Documentation Guidelines
------------------------

Please follow these guidelines when contributing to the documentation:

* Keep formatting consistent across pages. Update all pages when better ideas are discovered. Otherwise, follow the conventions established in existing content.
* Ensure that the ``make doc`` command completes with no errors or warnings.
* If the link-check portion of ``make doc`` reports that a URL is ``permanently`` redirected, update the link in the docs to use the new URL. Non-permanent redirects can be left as-is.
* Do not manually wrap lines in the ``.rst`` files. Insert newlines only as needed to achieve correctly formatted HTML, and let HTML wrap long lines and/or provide a scrollbar.
* Use one blank line between documentation elements (headers, paragraphs, code blocks, etc.) unless additional lines are necessary to achieve correctly formatted HTML.
* Remove all trailing whitespace.
* In general, avoid pronouns like "we" and "you". (Using "we" may be appropriate when synonymous with "The SRW Code Management Team", "The UFS Community", etc., when the context is clear.) Prefer direct, factual statements about what the code does, requires, etc.
* Use the `Oxford Comma <https://en.wikipedia.org/wiki/Serial_comma>`__.
* Follow the :rst:`RST Sections<basics.html#sections>` guidelines, underlining section headings with = characters, subsections with - characters, and subsubsections with ^ characters. If a further level of refinement is needed, use " to underline paragraph headers.
* In [[sub]sub]section titles, capitalize all "principal" words. In practice this usually means all words but articles (a, an, the), logicals (and, etc.), and prepositions (for, of, etc.). Always fully capitalize acronyms (e.g., YAML).
* Never capitalize proper names when their owners do not (e.g., write `"pandas" <https://pandas.pydata.org/>`__, not "Pandas", even at the start of a sentence) or when referring to a software artifact (e.g., write ``numpy`` when referring to the library, and "NumPy" when referring to the project).
* When referring to YAML constructs, ``block`` refers to an entry whose values is a nested collection of key/value pairs, while ``entry`` is a single key/value pair.
* When using the ``.. code-block::`` directive, align the actual code with the word ``code``. Also, when ``.. code-block::`` directives appear in bulleted or numberd lists, align them with the text following the space to the right of the bullet/number. Include a blank line prior to the coe content. For example:

  .. code-block:: text

     * Lorem ipsum

       .. code-block:: python

          n = 88

  or

  .. code-block:: text

     #. Lorem ipsum

        .. code-block:: python

           n = 88