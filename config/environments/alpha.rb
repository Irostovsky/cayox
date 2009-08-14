Merb.logger.info("Loaded Alpha Environment...")
Merb::Config.use { |c|
  c[:exception_details] = false
  c[:reload_classes]    = false
  c[:log_level]         = :info

  c[:log_file]  = Merb.root / "log" / "alpha.log"
  # or redirect logger using IO handle
  # c[:log_stream] = STDOUT
}
