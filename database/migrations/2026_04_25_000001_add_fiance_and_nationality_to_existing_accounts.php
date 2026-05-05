<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add fiancé/fiancée to the love relationship group of each account
        $loveGroups = DB::table('relationship_group_types')
            ->where('type', 'love')
            ->get();

        foreach ($loveGroups as $group) {
            $alreadyHasFiance = DB::table('relationship_types')
                ->where('relationship_group_type_id', $group->id)
                ->where('name_translation_key', 'LIKE', '%fianc%')
                ->exists();

            if (! $alreadyHasFiance) {
                DB::table('relationship_types')->insert([
                    [
                        'name_translation_key' => 'fiancé',
                        'name_reverse_relationship_translation_key' => 'fiancée',
                        'relationship_group_type_id' => $group->id,
                        'can_be_deleted' => true,
                        'type' => null,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ],
                    [
                        'name_translation_key' => 'fiancée',
                        'name_reverse_relationship_translation_key' => 'fiancé',
                        'relationship_group_type_id' => $group->id,
                        'can_be_deleted' => true,
                        'type' => null,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ],
                ]);
            }
        }

        // Add Nationality contact information type to each account
        $accounts = DB::table('accounts')->get();

        foreach ($accounts as $account) {
            $alreadyHasNationality = DB::table('contact_information_types')
                ->where('account_id', $account->id)
                ->where('type', 'nationality')
                ->exists();

            if (! $alreadyHasNationality) {
                DB::table('contact_information_types')->insert([
                    'account_id' => $account->id,
                    'name' => null,
                    'name_translation_key' => 'Nationality',
                    'protocol' => null,
                    'can_be_deleted' => true,
                    'type' => 'nationality',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        DB::table('relationship_types')
            ->whereIn('name_translation_key', ['fiancé', 'fiancée'])
            ->delete();

        DB::table('contact_information_types')
            ->where('type', 'nationality')
            ->delete();
    }
};
