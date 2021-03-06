# kopf

A job runner. Borne out of cron not preventing
a job running twice in parallel when one execution
takes long. It also manages processes to be run
continuously.

Things that are expected to terminate are called
jobs. They can run after a set interval since the last
start or end, or be triggered by cron expressions, by
the end of other jobs, or by plugins. Trigger events
can also add arguments to the job command being run.

Things that are not excepcted to terminate are called
procs. They are automatically restarted when they fail.

## Triggers

Trigger events can add arguments to a job's command.
These are collected for each run - if multiple triggers
happed during one run of a job the job is immediately
scheduled for another run, and all arguments collected
so far are passed in that next run.

If an `idle` time is set for a job it will that time
after the first new trigger (or the end of the previous
run) before being executed the next time. Extra triggers
that happen during that time are still collected into
the oncoming run, only triggers that happen after the
start need to go into the next run (and do schedule one).

That is, if triggers appear in bundles, `idle` is a way
to wait a short time after the first trigger so that
addional triggers can be done in the same job run.

## Cron expressions

One way to trigger jobs is to define cron expressions
on them - these generally follow the format of `crontab(5)`,
but obviously without the command part. Also all but the minute
entry can be omitted from the right, so instead of
`"5,35 * * * *"` for a job twice an hour `"5,35"`
is permitted as well, and `"0 17"` is sufficient to
run at teatime every day.

## Configuration

Configuration is done with a json (or yaml) file. It must
be a hash, containing an entry named `jobs` for the
defined jobs, and an entry `procs` for the defined procs.
Either can be omitted if it would be empty otherwise.

`jobs` and `procs` are hashs in turn.
The name of each entry therein is the job or proc name,
and the value is yet another hash, containing configuration
for that job or proc.

```
{
   "jobs":{
      "command":["/bin/echo","job output"],
      "pause": 10,
      "period": 30
   },
   "procs":{
      "command":["/usr/local/bin/tor","-f","tor.rc"],
   }
}
```
This simple example runs echo with a single argument `job output`
every 30 seconds, while keeping a spacing of at least ten seconds
between the end of one run and the start of the next (which is
unlikely to apply in this example); and also runs a `tor` process
continuously.


These configuration points apply for jobs and procs:

* `command` is either a string or an array of strings, defining
  the command to be executed. A string is executed as a shell
  command, an array of strings is directly executed, taking
  the first value as the command, and the remaining ones as
  arguments. Jobs do not need to have a command; they can
  also be used just to trigger other jobs.

* `dir` is a string specifying the directory in which to
  execute the command. If it is a relative path it is
  relative to the execution directory of `kopf` which is
  also the default value.

* `log-start` is a boolean whether to log the start and end
  of job executions; default `true`.

* `log-output` is a boolean whether to log the output
  of the job executions; default `false`.

* `idle` is a number in seconds specifying the minimum
  time between runs. For procs this defaults to 10 seconds,
  for jobs to zero. For jobs this is the time to wait after
  a trigger occurs before the job is run, and also the minimum
  time to wait after a job end before the next start due to
  a trigger that occurred during the previous run.

* `mail-to` is a string or an array of strings of email
  adresses to send the job's output to if not empty.

* `mail-from` is a string specifying the from address to
  be used in mails sent via `mail-to`.

* `title`, if set, is a string that is used instead of the job
  or proc's name in the hash for logging.

The following configuration points exist for jobs only:

* `period` is a number in seconds setting the minimum distance
  of the next start of the jobs from the previous start.
  Note that either `period` or `pause` (or both) must be
  set for a job to run regularly, otherwise it will only
  be started by cron expressions and triggers. The initial
  run happens at a random point within the maximum of
  `period` or `pause` seconds after startup.

* `pause` is a number in seconds setting the minimum distance
  of the next start of the jobs from the previous end. If `pause`
  causes a delay of the next start with respect to `period` the
  execution rhythm will slip accordingly.

* `random` is a number in seconds. A random fraction of this
  value is added to either `period` or `pause` in each round,
  so `{"random":3600,"period":3600}` will cause a job to run
  with one to two hours between starts.

* `cron` is either a string or an array of strings of cron expressions,
  or else a hash from cron expressions to strings or arrays
  of strings. The cron expressions determine when a cron entry
  fires (and causes the job to run), and in the hash form the
  respective hash values are appended to the static `command`
  for the next execution.

* `trigger` is either a string or an array of strings, or else
  a hash from strings to either. Trigger generally specify
  other jobs to trigger when this job ends. In the string
  or array of strings form each string is the name of a jobs
  to trigger; in the hash form the hash entry names are the
  jobs names to trigger, and the values are the extra arguments
  to pass to the respective jobs.

The following configuration points exists for procs only:

* `restart-on-file` is a string or an array of strings of files
  names. If one these files changes in size, modification time
  or existence, a running instance of the proc is terminated
  (via `SIGTERM`), and a new instance will be started. Relative
  file names are interpreted relative to the configured `dir`.

* `hup-on-file` is like `restart-on-file` except that a
  `SIGHUP` is delivered to the process instead of terminating it.

## Extra config files

The main configuration file may have an entry named `.d` containing
a path pattern. `kopf` tries to match the pattern against files
in the current directory, where each path component of the pattern
may contain a single asterisk which matches any characters in the
file names. Each file named this way is read as an additional
configuration file, and scanned only for `jobs` and `procs` sections.
The entries in these are put into the main `jobs* and `procs` sections,
while prepending the parts matched by the asterisks to the entry names.

E.g. with `".d":"sub-*dir/*.cfg"` entries in a file `sub-onedir/two.cfg`
will be prepended with `one/two/`, so an jobs entry `name` will
become `one/two/main` in the complete configuration.

## Issues

`kopf` does not try to kill procs or wait for jobs to finish
when terminated itself. It probably should.

A `protos` section with partial configs, and a
a `proto` config point to include those would
be helpful to avoid repetition (cron partially
does this by having global vars).

`restart-on-change` only `SIGTERM`s the proces
(and only the head process); it does no kill
after a timeout.

A control socket (e.g. for triggering jobs externally)
wouldn't hurt either.

For procs and long-running jobs, `mail-to` is suboptimal, and
should send partial output after a configurable time.

Logging and actual use aren't documented.

When run with pid 1 (as inside a docker container) it cleans
up zombie processes it inherited. This may interfere with
the regular process termination, but the cleanup is only
performed when a job or proc terminates, so chances are low.
