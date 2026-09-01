defmodule CaramelKitchen.Repo.Migrations.UpdateCourseTypeEnum do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'breakfast'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'lunch'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'dinner'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'side'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'snack'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'beverage'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'brunch'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'appetizer'"
    execute "ALTER TYPE course_type ADD VALUE IF NOT EXISTS 'desert'"
  end

  def down do
    :ok
  end
end
