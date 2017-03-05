# kopf

A job runner. Borne out of cron not preventing
a job running twice in parallel when one execution
takes long.

## Configuration

Configuration is done with a json (or yaml) file. It must
be a hash, containing one entry named `jobs` which is in
turn a hash. The name of each entry is the job name, and
the value is yet another hash, containing configuration
for that job.

```
{
   "jobs":{
      "command":["/bin/echo","job output"],
      "pause": 10,
      "period": 30
   }
}
```
This simple example runs echo with a single argument `job output`
every 30 seconds, while keeps a spacing of at least ten seconds
between the end of one run and the start of the next (which is
unlikely to apply in this example).

The following configuration points exist:

* `command` is either a string or an array of strings, defining
  the command to be executed. A string is executed as a shell
  command, an array of strings is directly executed, taking
  the first value as the command, and the remaining ones as
  arguments.

* `period` is a number in seconds setting the minimum distance
  of the next start of the jobs from the previous start.

* `pause` is a number in seconds setting the minimum distance
  of the next start of the jobs from the previous end. If `pause`
  causes a delay of the next start with respect to `period` the
  execution rhythm will slip accordingly.

* `random`

* `dir` is a string specifying the directory in which to
  execute the command. If it is a relative path it is
  relative to the execution directory of `kopf` which is
  also the default value.

* `cron` is either a string or an array of strings of cron expressions,
  or else a hash from cron expressions to strings or arrays
  of strings. The cron expressions determine when a cron entry
  fires (and causes the job to run), and in the hash form the
  respective hash values are appended to the static `command`
  for the next execution.

* `log-start` is a boolean whether to log the start and end
  of job executions; default `true`.

* `log-output` is a boolean whether to log the output
  of the job executions; default `false`.
