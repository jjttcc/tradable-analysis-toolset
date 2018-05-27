=begin
CREATE TABLE "tradable_analyzers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
"name" text
"event_id" integer
"is_intraday" boolean
"mas_session_id" integer
"created_at" datetime NOT NULL
"updated_at" datetime NOT NULL);
CREATE INDEX "index_tradable_analyzers_on_mas_session_id" ON "tradable_analyzers" ("mas_session_id");
=end

class TradableAnalyzer < ApplicationRecord
  belongs_to :mas_session

  public ###  Access

#!!!!TEMPORARY stub:
def period_type; 'monthly' end

  def description
    result = name.sub(/\s*\(.*/, '')
  end

end
