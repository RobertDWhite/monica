<?php

use App\Models\ContactImportantDate;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('contact_reminders', function (Blueprint $table) {
            $table->foreignIdFor(ContactImportantDate::class)
                ->nullable()
                ->after('contact_id')
                ->constrained()
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('contact_reminders', function (Blueprint $table) {
            $table->dropForeignIdFor(ContactImportantDate::class);
        });
    }
};
