# frozen_string_literal: true

namespace :sql_functions do
  desc "Test SQL functions from db/triggers/functions directory"
  task test: :environment do
    puts "🧪 Testing SQL Functions (SQL Capsules)\n\n"
    
    functions_dir = Rails.root.join('db/triggers/functions')
    
    unless functions_dir.exist?
      puts "❌ Functions directory not found: #{functions_dir}"
      exit 1
    end
    
    sql_files = Dir.glob(functions_dir.join('*.sql'))
    
    if sql_files.empty?
      puts "⚠️  No SQL function files found in #{functions_dir}"
      exit 0
    end
    
    puts "Found #{sql_files.length} SQL function file(s):\n\n"
    
    sql_files.each do |sql_file|
      function_name = File.basename(sql_file, '.sql')
      puts "📄 Testing: #{function_name}"
      puts "   File: #{sql_file}"
      
      begin
        sql_content = File.read(sql_file)
        
        # Check if function already exists
        existing = ActiveRecord::Base.connection.execute("
          SELECT proname 
          FROM pg_proc 
          WHERE proname = '#{function_name}'
        ").to_a
        
        if existing.empty?
          puts "   Status: Function does not exist in database"
          puts "   Loading function..."
          ActiveRecord::Base.connection.execute(sql_content)
          puts "   ✅ Function loaded successfully"
        else
          puts "   Status: Function already exists in database"
          puts "   Reloading function..."
          ActiveRecord::Base.connection.execute(sql_content)
          puts "   ✅ Function reloaded successfully"
        end
        
        # Verify function exists
        verified = ActiveRecord::Base.connection.execute("
          SELECT proname, prosrc 
          FROM pg_proc 
          WHERE proname = '#{function_name}'
        ").to_a
        
        if verified.any?
          puts "   ✅ Function verified in database"
        else
          puts "   ❌ Function verification failed"
        end
        
      rescue => e
        puts "   ❌ Error: #{e.message}"
        puts "   #{e.backtrace.first(3).join("\n   ")}"
      end
      
      puts ""
    end
    
    puts "✨ Testing complete!"
  end
  
  desc "List all SQL function files"
  task list: :environment do
    functions_dir = Rails.root.join('db/triggers/functions')
    
    unless functions_dir.exist?
      puts "Functions directory not found: #{functions_dir}"
      exit 1
    end
    
    sql_files = Dir.glob(functions_dir.join('*.sql'))
    
    if sql_files.empty?
      puts "No SQL function files found."
    else
      puts "SQL Function Files:\n\n"
      sql_files.each do |sql_file|
        puts "  📄 #{File.basename(sql_file)}"
        puts "     #{sql_file}\n\n"
      end
    end
  end
  
  desc "Check which SQL functions are used in triggers"
  task check_usage: :environment do
    puts "🔍 Checking SQL Function Usage in Triggers\n\n"
    
    functions_dir = Rails.root.join('db/triggers/functions')
    sql_files = Dir.glob(functions_dir.join('*.sql'))
    
    if sql_files.empty?
      puts "No SQL function files found."
      exit 0
    end
    
    # Get all function names from files
    function_names = sql_files.map { |f| File.basename(f, '.sql') }
    
    puts "SQL Functions in files:"
    function_names.each { |name| puts "  - #{name}" }
    puts ""
    
    # Check trigger migrations
    triggers_dir = Rails.root.join('db/triggers')
    trigger_files = Dir.glob(triggers_dir.join('*.rb'))
    
    puts "Checking trigger migrations:\n\n"
    function_names.each do |function_name|
      used = false
      trigger_files.each do |trigger_file|
        content = File.read(trigger_file)
        if content.include?(function_name)
          used = true
          puts "  ✅ #{function_name} - Used in: #{File.basename(trigger_file)}"
          break
        end
      end
      
      unless used
        puts "  ❌ #{function_name} - NOT used in any trigger"
      end
    end
    
    # Check trigger definitions
    app_triggers_dir = Rails.root.join('app/triggers')
    if app_triggers_dir.exist?
      app_trigger_files = Dir.glob(app_triggers_dir.join('*.rb'))
      puts "\nChecking trigger definitions:\n\n"
      function_names.each do |function_name|
        used = false
        app_trigger_files.each do |trigger_file|
          content = File.read(trigger_file)
          if content.include?(function_name)
            used = true
            puts "  ✅ #{function_name} - Used in: #{File.basename(trigger_file)}"
            break
          end
        end
        
        unless used
          puts "  ❌ #{function_name} - NOT used in any trigger definition"
        end
      end
    end
  end
end

