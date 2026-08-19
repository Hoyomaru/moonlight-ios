#!/usr/bin/env ruby
# 指定フォルダ配下の新規ソースファイルを、既存の project.pbxproj に自動登録するスクリプト。
# Xcode GUIを使わずに新規ファイルをビルド対象へ組み込むための仕組み。

require 'xcodeproj'

PROJECT_PATH = 'Moonlight.xcodeproj'
TARGET_NAME  = 'Moonlight'
WATCH_ROOT   = 'Limelight/Overlay' # このフォルダ配下を監視・自動登録する

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME }
raise "Target '#{TARGET_NAME}' not found" unless target

# WATCH_ROOT に対応するグループを取得 or 作成
def find_or_create_group(project, path_parts)
  group = project.main_group
  path_parts.each do |part|
    child = group.children.find { |c| c.respond_to?(:display_name) && c.display_name == part && c.is_a?(Xcodeproj::Project::Object::PBXGroup) }
    group = child || group.new_group(part)
  end
  group
end

root_group = find_or_create_group(project, WATCH_ROOT.split('/'))

compilable_ext = %w[.swift .m .mm]
existing_paths = project.files.map { |f| f.real_path.to_s }

added = []
Dir.glob("#{WATCH_ROOT}/**/*").each do |file_path|
  next unless File.file?(file_path)
  ext = File.extname(file_path)
  next unless compilable_ext.include?(ext) || ext == '.h'

  abs_path = File.expand_path(file_path)
  next if existing_paths.include?(abs_path)

  file_ref = root_group.new_file(file_path)
  if compilable_ext.include?(ext)
    target.source_build_phase.add_file_reference(file_ref)
  end
  added << file_path
end

if added.empty?
  puts "No new files to register."
else
  project.save
  puts "Registered #{added.length} new file(s): #{added.join(', ')}"
end
