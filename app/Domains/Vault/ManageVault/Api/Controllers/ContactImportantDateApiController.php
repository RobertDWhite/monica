<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageContactImportantDates\Services\CreateContactImportantDate;
use App\Domains\Contact\ManageContactImportantDates\Services\DestroyContactImportantDate;
use App\Domains\Contact\ManageContactImportantDates\Services\UpdateContactImportantDate;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Important dates
 */
class ContactImportantDateApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateContactImportantDate)->execute($this->baseData($request, $vaultId, $contactId) + [
            'label' => $request->input('label'),
            'day' => $request->input('day'),
            'month' => $request->input('month'),
            'year' => $request->input('year'),
            'contact_important_date_type_id' => $request->input('contact_important_date_type_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $dateId)
    {
        (new UpdateContactImportantDate)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_important_date_id' => (int) $dateId,
            'label' => $request->input('label'),
            'day' => $request->input('day'),
            'month' => $request->input('month'),
            'year' => $request->input('year'),
            'contact_important_date_type_id' => $request->input('contact_important_date_type_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $dateId)
    {
        (new DestroyContactImportantDate)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_important_date_id' => (int) $dateId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
