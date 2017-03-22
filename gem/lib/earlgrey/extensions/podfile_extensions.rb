#
#  Copyright 2016 Google Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

module EarlGrey
  module PodfileExtension
    def use_earlgrey!(flag = true)
      current_target_definition.use_earlgrey!(flag)
    end
  end
  module TargetDefinitionExtension
    def use_earlgrey!(flag = true)
      set_hash_value('uses_earlgrey', flag)
    end

    def uses_earlgrey?
      if internal_hash['uses_earlgrey'].nil?
        root? ? false : parent.uses_earlgrey?
      else
        get_hash_value('uses_earlgrey')
      end
    end
  end
end

module Pod
  class Podfile
    class TargetDefinition
      orig_verbose = $VERBOSE
      $VERBOSE = nil
      HASH_KEYS = (HASH_KEYS + ['uses_earlgrey']).freeze
      $VERBOSE = orig_verbose
      include EarlGrey::TargetDefinitionExtension
    end
  end

  class Podfile
    include EarlGrey::PodfileExtension
  end
end
