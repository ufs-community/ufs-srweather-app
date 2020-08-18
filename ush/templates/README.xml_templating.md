# Rocoto XML templating

## Jinja Templating

Jinja2 is a fast, widely used, secure templating language for Python.
Documentation is here: [Jinja2
Docs](https://jinja.palletsprojects.com/en/2.11.x?target=_blank)

### Brief overview

A Python script parses a Jinja template, looks for standard template
fields containing variables known to Python. Finding all the template
variables, it renders the desired output, which can then be saved as
output.

Inside a Jinja Template file, you will see several place holders:

- `{% ... %}` for Statements 
  - In our context, the are mainly control structures like if and for
  loops

- `{{ ... }}` for Expressions to print to the template output
  - Used mainly by `regional_workflow` templates to fill in variables

- `{# ... #}` for Comments not included in the template output

- `#  ... ##` for Line Statements
  - Not used for `regional_workflow` templates

---

## Templates for Rocoto XML

The `regional_workflow` repository uses `ush/fill_template.py` to do
this work. And Jinja templates are used for the Rocoto XML, and with the
FV3 diag tables.


### Entities - XML variables with template Expressions

---

**Example:** `<!ENTITY MODEL      "{{ model }}">` 

- Add ENTITIES in XML using `{{ ... }}` fields for the values.
  - Any variable inside the curly braces will need to be supplied by the
  Python script filling the template. Add the value to the settings
  variable in `ush/generate_workflow.sh`.
- Setting proper XML ENTITIES should be limited to variables that are only
needed for setting cycle-specific values, i.e., submitting the job, passing
in a date, tracking locations of files for dependencies, etc.
- Static settings not used directly by the XML (only used by J-Jobs
or ex-scripts) should be set in `ush/setup.sh` or
`ush/default_configs.sh` so that it ends up in an experiment's
`var_defns.sh` file
- Static settings included in the XML only serve to make the submit
process cumbersome for users who wish to submit jobs manually (without
Rocoto).

### In-line template Expressions -- Python variables

---

**Example:** `<nodes>{{ nnodes_make_grid }}:ppn={{ ppn_make_grid }}</nodes>`

- Values can be filled "in-place" without setting an XML ENTITY. This
means that you won't be able to reference this value anywhere else in
the XML file once the template has been rendered.
- Reducing indirection for variables that are used sparingly can be
easier to understand and manage once the template is filled.

### ENTITY vs In-Line Expression??

---

**Example:** Are you asking yourself THIS:

`<!ENTITY NNODES_MAKE_GRID      "{{ nnodes_make_grid }}">` \
`<!ENTITY PPN_MAKE_GRID         "{{ ppn_make_grid }}">`

...

`<nodes>&NNODES_MAKE_GRID;:ppn=&PPN_MAKE_GRID;</nodes>`

  -- OR THIS --

`<nodes>{{ nnodes_make_grid }}:ppn={{ ppn_make_grid }}</nodes>`

???


- Identical values set for the same purpose in many places (~3+) should
probably be an ENTITY. Otherwise, apply the KISS Method.
- Entities can help with the search process as XML files grow
ever-longer. If you envision needing to search on a particular ENTITY
throughout, set it up top to help end-user (YOU!) find all occurrences
later.
- Use of Jinja Statements like loops and if statements should always be
done in-line for the sake of clarity.


### Handling Optional Tasks

---

There are few things to consider when adding optional tasks to the
XML. 

- When a task is turned off, but does not run, Rocoto can't easily mark
a cycle as "complete". Instead, consider leaving the task out of the XML
altogether with a Jinja control structure.
- When the task is NOT included in an XML (flag is turned off), a
subsequent task dependency must be treated with care. You probably want
to add an ENTITY to be treated as an "ON/OFF" flag so that task
dependencies are never evaluated if they aren't included.
- Add a Jinja "if statement" along with your boolean flag to remove the
whole task from the final template.

These all work together like this:

In `ush/generate_workflow.sh`, the `run_task_make_grid` flag is set to "False" to
turn off running verification.

In `ush/templates/FV3LAM_wflow.xml`:

1. Set an entity for use in dependencies.
2. Add a Jinja if statement around the optional task.
3. Treat subsequent dependencies carefully.

Altogether it looks like this:

    <!-- Uppercase for consistency when using a <streq> dependency -->
    <!ENTITY RUN_TASK_MAKE_GRID      "{{ run_task_make_grid | upper }}">

    ...

    <!-- Anything inside this if block is included ONLY if run_task_make_grid == True -->
    {% if run_task_make_grid %}
      <task name=...>

      </task>
    {% endif %}

    <!-- Task X depends on completion of run_task_make_grid or a file existing -->

      <task name=...>

        <dependency>
          <or>
            <!-- Evaluate a task dependency ONLY if RUN_TASK_MAKE_GRID is
            TRUE. The <taskdep> will never be evaluated otherwise. -->
            <and>
              <streq><left>&RUN_TASK_MAKE_GRID;</left><right>TRUE</right></streq>
              <taskdep task="make_grid"/>
            </and>

            <!-- The existence of a data file will also work when the task
            doesn't run -->
            <datadep age="00:00:00:05">&LOGDIR;/make_grid_task_complete.txt</datadep>
          </or>
        </dependency>

      </task>

