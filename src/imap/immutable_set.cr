class ImmutableSet(T)
  @set : Set(T)

  def initialize(*params : T)
    @set = Set.new(params)
  end

  def each
    @set.each
  end

  def size
    @set.size
  end

  def to_s(io)
    io << "ImmutableSet{"
    join ", ", io, &.inspect(io)
    io << '}'
  end

  def empty?
    @set.empty?
  end

  def inspect(io)
    to_s(io)
  end

  def object_id
    @set.object_id
  end

  def includes?(obj)
    @set.includes?(obj)
  end

  def intersects?(other)
    @set.intersects?(other)
  end

  def pretty_print(pp) : Nil
    pp.list("ImmutableSet{", @set, "}")
  end
end
