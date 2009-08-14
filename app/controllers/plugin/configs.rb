module Plugin
  class Configs < Application
    layout nil
    provides :xml

    def default
      render
    end

  end
end
