namespace :w000t do
  desc 'w000t | check old w000ts'
  task :check_old_w000ts do
    # We get all the w000ts that haven't been checked for one day
    # And get only one part of it so that in 24 hours we're sure to check them
    # all
    W000t.all.where(:"url_info.last_check".lte => Time.now - 1.day)
             .limit(W000t.all.count / 48)
             .each do |w|
      logger.info "Checking #{w.url_info.url}"
      w.create_task
      logger.info 'Done'
    end
  end
end
