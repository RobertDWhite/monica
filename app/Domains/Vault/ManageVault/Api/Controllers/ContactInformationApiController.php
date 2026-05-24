<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageContactInformation\Services\CreateContactInformation;
use App\Domains\Contact\ManageContactInformation\Services\DestroyContactInformation;
use App\Domains\Contact\ManageContactInformation\Services\UpdateContactInformation;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Contact information
 */
class ContactInformationApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateContactInformation)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_information_type_id' => $request->input('contact_information_type_id'),
            'contact_information_kind' => $request->input('contact_information_kind'),
            'data' => $request->input('data'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $informationId)
    {
        (new UpdateContactInformation)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_information_id' => (int) $informationId,
            'contact_information_type_id' => $request->input('contact_information_type_id'),
            'contact_information_kind' => $request->input('contact_information_kind'),
            'data' => $request->input('data'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $informationId)
    {
        (new DestroyContactInformation)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_information_id' => (int) $informationId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
