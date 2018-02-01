# module Trailblazer
#   class Activity
#     module Task
#       # Convenience functions for tasks. Totally optional.

#       # Task::Binary aka "step"
#       # Step is binary task: true=> Right, false=>Left.
#       # Step call proc.(options, flow_options)
#       # Step is supposed to run Option::KW, so `step` should be Option::KW.
#       #
#       # Returns task to call the proc with (options, flow_options), omitting `direction`.
#       # When called, the task always returns a direction signal.
#       def self.Binary(step, on_true=Activity::Right, on_false=Activity::Left)
#         ->(*args) do # Activity/Task interface.
#           [ step.(*args) ? on_true : on_false, *args ] # <=> Activity/Task interface
#         end
#       end
#     end
#   end
# end
