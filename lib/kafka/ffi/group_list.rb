# frozen_string_literal: true

require "ffi"
require "kafka/ffi/group_info"

module Kafka::FFI
  class GroupList < ::FFI::Struct
    layout(
      :groups,    :pointer,
      :group_cnt, :int
    )

    # Returns information about the consumer groups in the cluster.
    #
    # @return [Array<GroupInfo>] Group metadata
    def groups
      self[:group_cnt].times.map do |i|
        GroupInfo.new(self[:groups] + (i * GroupInfo.size))
      end
    end

    # Release the resources used by the group list back to the system
    def destroy
      ::Kafka::FFI.rd_kafka_group_list_destroy(self)
    end
  end
end
